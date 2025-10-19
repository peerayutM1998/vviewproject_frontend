import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Mainpage extends StatelessWidget {
  final List<String> buttons = [
    'อ่านข้อความ',
    'จดจำใบหน้า',
    'สิ่งกีดขวาง',
    'ระบุสี',
    'ธนบัตร',
  ];

  final Map<String, String> buttonRoutes = {
    'อ่านข้อความ': '/readText',
    'จดจำใบหน้า': '/desface',
    'สิ่งกีดขวาง': '/descobject',
    'ระบุสี': '/descolor',
    'ธนบัตร': '/desbank',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.asset(
                  'assets/icon.png',
                  height: 80,
                ),
              ),
              SizedBox(height: 30),
              for (var text in buttons)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 32.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, buttonRoutes[text]!);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF002DAC),
                      minimumSize: Size(double.infinity, 70),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 20),
                      elevation: 5,
                    ),
                    child: Text(
                      text,
                      style: GoogleFonts.roboto( // ใช้ Roboto จาก Google Fonts
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      semanticsLabel: text, // เพิ่มสำหรับ screen reader
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}