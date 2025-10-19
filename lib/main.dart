import 'package:flutter/material.dart';
import 'package:vviewproject/mainpage.dart';
import 'package:vviewproject/screen/BanknotePage.dart';
import 'package:vviewproject/screen/ColorIdentificationPage.dart';
import 'package:vviewproject/screen/FaceRecognitionPage.dart';
import 'package:vviewproject/screen/ObstaclePage.dart';
import 'package:vviewproject/screen/ReadTextPage.dart';
import 'package:vviewproject/screen/describeBank.dart';
import 'package:vviewproject/screen/describeFace.dart';
import 'package:vviewproject/screen/describeColor.dart';
import 'package:vviewproject/screen/describeObject.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'vview',
      home: Mainpage(),
      routes: {
        '/readText': (context) => ReadTextPage(),
        '/faceRecognition': (context) => FaceRecognitionPage(),
        '/obstacle': (context) => ObstacleDetectionPage(),
        '/colorIdentification': (context) => ColorIdentificationPage(),
        '/banknote': (context) => BanknotePage(),
        '/desbank': (context) => describeBank(),
        '/desface': (context) => describeFace(),
        '/descolor': (context) => describeColor(),
        '/descobject': (context) => describeObject(),
      },
    );
  }
}
