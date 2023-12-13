import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esp32sensor/shared/loading.dart';
import 'package:esp32sensor/utils/constants/constants.dart';
import 'package:esp32sensor/utils/functions/formatter.dart';
import 'package:esp32sensor/utils/pojo/npk.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class NPKAnalyzer extends StatefulWidget {
  final String value;
  final bool isCrop;

  const NPKAnalyzer({super.key, required this.value, required this.isCrop});

  @override
  State<NPKAnalyzer> createState() => _NPKAnalyzerState();
}

class _NPKAnalyzerState extends State<NPKAnalyzer> {
  bool _isLoading = false;
  int _nitrogen = 0;
  int _phosphorus = 0;
  int _potassium = 0;
  String _lastUpdatedText = 'Fetching...';
  Map<String, Range> _idealRange = {};
  final List<Crop> _crops = [];

  final CollectionReference _npkCollectionReference =
      FirebaseFirestore.instance.collection('npk_readings');

  void getCrops() async {
    List<Crop> crops = [];
    setState(() {
      _crops.clear();
    });
    await FirebaseFirestore.instance
        .collection('npk_ideal_ranges')
        .where('type', isEqualTo: 'crop')
        .get()
        .then((e) {
      for (var element in e.docs) {
        Map? data = element.data();
        crops.add(Crop(
          element.id,
          data['image'] ?? 'assets/images/soil.png',
          data['season'] ?? '',
          NPKIdealRange(
            data['N'] ?? '100-150',
            data['P'] ?? '100-150',
            data['K'] ?? '100-150',
          ),
        ));
      }

      for (var crop in crops) {
        if (crop.npkIdealRange.isInRange(_nitrogen, _phosphorus, _potassium)) {
          setState(() {
            _crops.add(crop);
          });
        }
      }
      if (kDebugMode) {
        print('SUITABLE CROPS:\n $_crops');
      }
    }).onError((error, stackTrace) {
      Get.snackbar('Error', error.toString());
      if (kDebugMode) {
        print('error - getCrops: $error');
      }
    });
  }

  void getIdealRange() async {
    setState(() {
      _isLoading = true;
    });
    await FirebaseFirestore.instance
        .collection('npk_ideal_ranges')
        .doc(widget.value)
        .get()
        .then((value) {
      String nRange = value.data()?['N'] ?? '100-150';
      String pRange = value.data()?['P'] ?? '100-150';
      String kRange = value.data()?['K'] ?? '100-150';
      if (kDebugMode) {
        print('NPK IDEAL RANGE FOR ${widget.value}:\n ${value.data()}');
      }
      setState(() {
        _idealRange = {
          'N': Range(
              int.parse(nRange.split('-')[0]), int.parse(nRange.split('-')[1])),
          'P': Range(
              int.parse(pRange.split('-')[0]), int.parse(pRange.split('-')[1])),
          'K': Range(
              int.parse(kRange.split('-')[0]), int.parse(kRange.split('-')[1])),
        };
        _isLoading = false;
      });
    }).onError((error, stackTrace) {
      Get.snackbar('Error', error.toString());
      if (kDebugMode) {
        print('error - getIdealRange: $error');
      }
      setState(() {
        _isLoading = false;
      });
    });
  }

  void fetchSensorData() async {
    // make query for latest doc in npk_readings collection and listen to it
    _npkCollectionReference
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((event) {
      if (event.docs.isNotEmpty) {
        Map? data = event.docs.first.data() as Map?;
        if (kDebugMode) {
          print('NPK READING FROM SENSOR:\n $data');
        }
        setState(() {
          _lastUpdatedText = dateFormatter(data?['timestamp'].toDate());
          _nitrogen = data?['N'] ?? 0;
          _phosphorus = data?['P'] ?? 0;
          _potassium = data?['K'] ?? 0;
        });
        getCrops();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    getIdealRange();
    fetchSensorData();
  }

  @override
  void dispose() {
    _npkCollectionReference.snapshots().listen((event) {}).cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'NPK Analyzer ',
              style: TextStyle(fontSize: 18),
            ),
            Text(' (${widget.value}${widget.isCrop ? "" : " Soil"})',
                style: const TextStyle(fontSize: 16, color: Colors.black54))
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.0,
      ),
      body: _isLoading
          ? SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.black54,
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      'Fetching ideal range...',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : (_nitrogen == 0 && _phosphorus == 0 && _potassium == 0)
              ? Loading(
                  size: 40,
                )
              : Column(children: [
                  // make a banner to show last updated status
                  Container(
                    width: MediaQuery.of(context).size.width,
                    color: Colors.blueAccent,
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        const Text(
                          'Last Updated: ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _lastUpdatedText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <NPKData>[
                      NPKData('Nitrogen', 'N', _nitrogen, Colors.blue,
                          _idealRange['N']!.getStatus(_nitrogen)),
                      NPKData('Phosphorus', 'P', _phosphorus, Colors.orange,
                          _idealRange['P']!.getStatus(_phosphorus)),
                      NPKData('Potassium', 'K', _potassium, Colors.purple,
                          _idealRange['K']!.getStatus(_potassium)),
                    ]
                        .map((e) => Column(
                              children: [
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 150,
                                      height: 150,
                                      child: SfRadialGauge(
                                        enableLoadingAnimation: true,
                                        animationDuration: 1000,
                                        axes: <RadialAxis>[
                                          RadialAxis(
                                            canScaleToFit: true,
                                            minorTicksPerInterval: 10,
                                            majorTickStyle:
                                                const MajorTickStyle(
                                                    thickness: 1,
                                                    length: 10,
                                                    color: Color.fromARGB(
                                                        255, 116, 116, 116)),
                                            minorTickStyle:
                                                const MinorTickStyle(
                                                    thickness: 0.5,
                                                    length: 7,
                                                    color: Color.fromARGB(
                                                        255, 116, 116, 116)),
                                            minimum: 0.0,
                                            maximum: _idealRange[e.symbol]!
                                                    .start
                                                    .toDouble() +
                                                _idealRange[e.symbol]!
                                                    .end
                                                    .toDouble(),
                                            interval: ((_idealRange[e.symbol]!
                                                            .start
                                                            .toDouble() +
                                                        _idealRange[e.symbol]!
                                                            .end
                                                            .toDouble()) /
                                                    10)
                                                .floorToDouble(),
                                            axisLabelStyle:
                                                const GaugeTextStyle(
                                                    fontSize: 8),
                                            axisLineStyle: const AxisLineStyle(
                                                thickness: 5,
                                                color: Colors.black),
                                            ranges: <NPKRange>[
                                              NPKRange(
                                                  'Low'.tr,
                                                  0,
                                                  _idealRange[e.symbol]!.start,
                                                  Colors.red),
                                              NPKRange(
                                                  'Ideal'.tr,
                                                  _idealRange[e.symbol]!.start,
                                                  _idealRange[e.symbol]!.end,
                                                  Colors.green),
                                              NPKRange(
                                                  'High'.tr,
                                                  _idealRange[e.symbol]!.end,
                                                  _idealRange[e.symbol]!.start +
                                                      _idealRange[e.symbol]!
                                                          .end,
                                                  Colors.red),
                                            ]
                                                .map((r) => GaugeRange(
                                                      startValue:
                                                          r.start.toDouble(),
                                                      endValue:
                                                          r.end.toDouble(),
                                                      startWidth: 15,
                                                      endWidth: 15,
                                                      rangeOffset: -5.0,
                                                      label: r.label,
                                                      labelStyle:
                                                          const GaugeTextStyle(
                                                              fontSize: 10,
                                                              color:
                                                                  Colors.white),
                                                      // gradient: SweepGradient(
                                                      //     colors: <Color>[e.color.withOpacity(.6), e.color],
                                                      //     stops: const <double>[0.25, 0.75]),
                                                      color: r.color,
                                                    ))
                                                .toList(),
                                            pointers: <GaugePointer>[
                                              NeedlePointer(
                                                value: e.value * 1.00,
                                                enableAnimation: true,
                                                needleLength: 0.5,
                                                needleStartWidth: 1,
                                                needleEndWidth: 4,
                                              )
                                            ],
                                            annotations: <GaugeAnnotation>[
                                              GaugeAnnotation(
                                                widget: Text(
                                                  e.symbol,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                      color: e.color),
                                                ),
                                                positionFactor: 0.5,
                                                angle: 90,
                                              )
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          e.label,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: e.color,
                                            fontSize: 20,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          children: [
                                            const Text(
                                              'Current Reading: ',
                                              style: TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              '${e.value}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          children: [
                                            const Text(
                                              'Ideal Reading: ',
                                              style: TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              _idealRange[e.symbol].toString(),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          children: [
                                            const Text(
                                              'Status: ',
                                              style: TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              e.status.label,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: e.status.color,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ))
                        .toList(),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  //  make a view for suitable crops list in the current npk range which is inside _crops variable
                  const Text(
                    'Suitable Crops',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  SizedBox(
                      width: MediaQuery.of(context).size.width - 20,
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: _crops
                            .map((e) => SizedBox(
                                  width: 100,
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        e.image,
                                        height: 80,
                                        width: 80,
                                      ),
                                      Text(
                                        e.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ))
                ]),
    );
  }
}
