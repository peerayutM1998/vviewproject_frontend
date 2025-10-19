import 'package:flutter/material.dart';
import 'package:vviewproject/screen/ObstaclePage.dart';
import 'package:google_fonts/google_fonts.dart';

class Secdesobject extends StatefulWidget {
  const Secdesobject({super.key});

  @override
  State<Secdesobject> createState() => _SecdesobjectState();
}

class _SecdesobjectState extends State<Secdesobject> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ===== AppBar ด้านบน =====
      appBar: AppBar(
        title: Text(
          'ฟังก์ชันสิ่งกีดขวาง',
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

      // ===== เนื้อหา =====
      body: Container(
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // หัวข้อหลัก
                    Text(
                      'แนะนำการใช้งานฟังก์ชันสิ่งกีดขวาง',
                      style: GoogleFonts.prompt(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15136E),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // คำอธิบายสั้น
                    Text(
                      '\t\t\t\t\tควรถ่ายภาพด้านหน้าทุกครั้งเมื่อมีการเลี้ยว โดยกดถ่ายภาพเพื่อให้ระบบสามารถประมวลผลระยะทางและระบุประเภทของสิ่งกีดขวางได้อย่างถูกต้อง',
                      style: GoogleFonts.prompt(
                        fontSize: 18,
                        color: Colors.black87,
                        height: 2,
                      ),
                    ),




                    // เว้นระยะก่อนรูปภาพ
                    const SizedBox(height: 30),

                    // แถวรูปตัวอย่าง
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Expanded(
                          flex: 8,
                          child: _ImageCardFill(
                            imagePath: 'assets/obj2.png',
                            height: 200,
                          ),
                        ),
                        SizedBox(width: 12),
                        // ถ้ามีรูปขวา เพิ่ม Expanded อีกตัวได้
                        // Expanded(
                        //   flex: 6,
                        //   child: _ImageCardFill(
                        //     imagePath: 'assets/face_right.png',
                        //     height: 180,
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      // ===== AppBar ด้านล่าง =====
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF15136E),
        child: InkWell(
          onTap: () {
            // กลับไปหน้า FaceRecognitionPage (ไม่ใช้ pop)
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ObstacleDetectionPage()),
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

/// การ์ดรูปภาพที่ "ไม่ครอป" ภาพ (ใช้ BoxFit.contain)
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
            fit: BoxFit.contain, // เห็นภาพครบ ไม่ถูกตัด
          ),
        ),
      ),
    );
  }
}


