import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vviewproject/screen/BanknotePage.dart';

class Secdesbank extends StatefulWidget {
  const Secdesbank({super.key});

  @override
  State<Secdesbank> createState() => _SecdesbankState();
}

class _SecdesbankState extends State<Secdesbank> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ฟังก์ชันธนบัตร',
          style: GoogleFonts.prompt(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF15136E),
        elevation: 4,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // กล่องสีฟ้า (ตอนนี้คุณตั้ง offset เป็น 50 ถ้าจะเลื่อนขึ้น/ลง ปรับตัวเลขนี้ได้)
                    Transform.translate(
                      offset: const Offset(0, 50),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB6E0FF),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          'ฟังก์ชันธนบัตรสามารถคำนวณมูลค่ารวมของธนบัตรที่ปรากฏในภาพได้โดยอัตโนมัติ',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.prompt(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.8,
                          ),
                        ),
                      ),
                    ),

                    // >>> เพิ่มช่องว่าง 5 บรรทัดก่อนหัวข้อ "แนะนำ..."
                    const SizedBox(height: 100),

                    Text(
                      'แนะนำการใช้งานฟังก์ชันธนบัตร',
                      style: GoogleFonts.prompt(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      '\t\t\t\t\tโปรดวางธนบัตรให้แยกจากกันโดยไม่ซ้อนทับ \n'
                          'และหลีกเลี่ยงการถ่ายภาพธนบัตรเกิน 10 ใบภายในหนึ่งภาพ '
                          'เพื่อให้ผลการประมวลผลมีความแม่นยำ',
                      style: GoogleFonts.prompt(
                        fontSize: 18,
                        color: Colors.black87,
                        height: 2,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Expanded(
                          flex: 6,
                          child: _ImageCardFill(
                            imagePath: 'assets/bank1.png',
                            height: 200,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 7,
                          child: _ImageCardFill(
                            imagePath: 'assets/bank2.png',
                            height: 180,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF15136E),
        child: InkWell(
          onTap: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const BanknotePage()),
            );
          },
          splashColor: Colors.white.withOpacity(0.1),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Center(
              child: Text(
                'ย้อนกลับ',
                style: TextStyle(
                  fontFamily: 'Prompt',
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
                semanticsLabel: 'ย้อนกลับ',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageCardFill extends StatelessWidget {
  final String imagePath;
  final double height;

  const _ImageCardFill({required this.imagePath, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: Colors.white,
          alignment: Alignment.center,
          child: Image.asset(
            imagePath,
            width: double.infinity,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

