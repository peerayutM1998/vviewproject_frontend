import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vviewproject/screen/BanknotePage.dart';
import 'package:vviewproject/screen/secdesBank.dart';

class describeBank extends StatelessWidget {
  const describeBank({super.key});

  static const Color brandBlue = Color(0xFF15136E);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // รูป bank.png
                  Image.asset(
                    'assets/bank3.png',
                    width: size.width * 0.7,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),

                  // หัวข้อ
                  Text(
                    'แนะนำการใช้งานฟังก์ชันธนบัตร',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.prompt(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      height: 2,
                      color: brandBlue,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // คำอธิบาย
                  Text(
                    'เพื่อทราบความสามารถในการใช้งานเเละข้อจำกัดของฟังก์ชัน\n'
                        'โปรดกดปุ่ม รับฟังรายละเอียด ด้านล่าง',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.prompt(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.black87,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: size.height * 0.05),

                  // ปุ่มอยู่ตรงกลาง
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ปุ่ม "รับฟังรายละเอียด"
                        SizedBox(
                          width: 180,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: brandBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const Secdesbank(),
                                ),
                              );
                            },
                            child: Text(
                              'รับฟังรายละเอียด',
                              style: GoogleFonts.prompt(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // ปุ่ม "ปิด"
                        SizedBox(
                          width: 80,
                          height: 50,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: brandBlue, width: 2),
                              foregroundColor: brandBlue,
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BanknotePage(),
                                ),
                              );
                            },
                            child: Text(
                              'ปิด',
                              style: GoogleFonts.prompt(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
