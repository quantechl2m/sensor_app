import 'package:flutter/material.dart';

var textInputDecoration = InputDecoration(
    labelStyle: const TextStyle(
        fontFamily: 'JosefinSans', color: Color.fromARGB(255, 68, 158, 115)),
    fillColor: Colors.white,
    filled: true,
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(color: Colors.white, width: 2.0)),
    focusedBorder: const OutlineInputBorder(
        borderSide:
            BorderSide(color: Color.fromARGB(255, 68, 158, 115), width: 2.0)));

Map<String, Color> colors = {
  'green': const Color.fromARGB(255, 78, 181, 131),
  'lightGreen': const Color.fromARGB(255, 144, 177, 161),
  'darkGreen': const Color.fromARGB(255, 50, 135, 94),
  'lightBlue1': const Color.fromARGB(255, 152, 207, 225),
  'lightBlue2': const Color.fromARGB(255, 219, 243, 251),
  'white': Colors.white,
  'black': Colors.black,
  'grey': Colors.grey,
  'darkGrey': Colors.grey[700]!,
  'lightGrey': Colors.grey[300]!,
};

Map<String, String> customIcons = {
  'waterIcon': 'assets/icons/water.png',
  'soilIcon': 'assets/icons/soil.png',
  'gasIcon': 'assets/icons/gas.png',
  'bioIcon': 'assets/icons/bio.png',
  'translationIcon': 'assets/icons/translation.jpg',
  'diseaseDetectorIcon': 'assets/icons/diseaseDetector.jpg',
  'npkSensorIcon': 'assets/icons/npkSensor.jpg',
  'detectionIcon': 'assets/icons/detection.gif',
  'seedlingIcon': 'assets/icons/seedling.svg',
};

Map<String, String> images = {
  'homeBanner': 'assets/images/home.jpg',
  'agricultureBanner': 'assets/images/agriculture.png',
  'diseaseDetectorBanner': 'assets/images/detectorBanner.jpg',
  'npkSensorBanner': 'assets/images/npkBanner.jpg',
  'kharif': 'assets/images/kharif.png',
  'rabi': 'assets/images/rabi.png',
};

class Status {
  final String label;
  final Color color;

  Status(this.label, this.color);
}

class Range {
  final int start;
  final int end;

  Range(this.start, this.end);

  bool isInRange(int value) {
    return value >= start && value <= end;
  }

  Status getStatus(int value) {
    // make very low low moderate high and very high and moderate is good as green others are bad
    int diff = end - start;
    if (value < start - diff / 2) {
      return Status('Very Low', Colors.red[900]!);
    } else if (value < start) {
      return Status('Low', Colors.red[400]!);
    } else if (value <= end) {
      return Status('Moderate', Colors.green);
    } else if (value <= end + diff / 2) {
      return Status('High', Colors.red[400]!);
    } else {
      return Status('Very High', Colors.red[900]!);
    }
  }

  @override
  String toString() {
    return  '$start-$end';
  }
}

class NPKIdealRange {
  final Range nitrogen;
  final Range phosphorus;
  final Range potassium;

  NPKIdealRange(String nitrogen, String phosphorus, String potassium)
      : nitrogen = Range(int.parse(nitrogen.split('-')[0]), int.parse(nitrogen.split('-')[1])),
        phosphorus = Range(int.parse(phosphorus.split('-')[0]), int.parse(phosphorus.split('-')[1])),
        potassium = Range(int.parse(potassium.split('-')[0]), int.parse(potassium.split('-')[1]));

  Status getNitrogenStatus(int value) {
    return nitrogen.getStatus(value);
  }

  Status getPhosphorusStatus(int value) {
    return phosphorus.getStatus(value);
  }

  Status getPotassiumStatus(int value) {
    return potassium.getStatus(value);
  }

  bool isNitrogenInRange(int value) {
    return nitrogen.isInRange(value);
  }

  bool isPhosphorusInRange(int value) {
    return phosphorus.isInRange(value);
  }

  bool isPotassiumInRange(int value) {
    return potassium.isInRange(value);
  }

  bool isInRange(int nitrogen, int phosphorus, int potassium) {
    return isNitrogenInRange(nitrogen) && isPhosphorusInRange(phosphorus) &&
        isPotassiumInRange(potassium);
  }

  @override
  String toString() {
    return 'NPKIdealRange(nitrogen: $nitrogen, phosphorus: $phosphorus, potassium: $potassium)';
  }
}

class Crop {
  final String name;
  final String image;
  final String season;
  final NPKIdealRange npkIdealRange;

  Crop(this.name, this.image, this.season, this.npkIdealRange);

  @override
  String toString() {
    return 'Crop(name: $name, image: $image, season: $season, npkIdealRange: $npkIdealRange)';
  }
}