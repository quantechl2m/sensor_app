import 'dart:io';

import 'package:esp32sensor/utils/apis/api.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

class SoilDetection {
  late String soilType;
  late String soilDataJson;
  BuildContext context;
  File? imageFile;

  SoilDetection({
    required this.context,
    required this.imageFile,
  });

  Future<void> detectSoil() async {
    if (kDebugMode) {
      print('SoilDetection.detectSoil called...');
    }
    await APIs.imageDetection(imageFile!, '', context, 1).then((value) {
      if (value == null) {
        soilType = '';
        return;
      }
      soilType = value.toString();
    });
  }
}
