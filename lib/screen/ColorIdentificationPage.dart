import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vviewproject/services/camera_service.dart';
import 'package:vviewproject/services/tts_service.dart';
import 'package:vviewproject/mainpage.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';

class ColorIdentificationPage extends StatefulWidget {
  const ColorIdentificationPage({super.key});

  @override
  State<ColorIdentificationPage> createState() => _ColorIdentificationPageState();
}

class _ColorIdentificationPageState extends State<ColorIdentificationPage> {
  final CameraService _cameraService = CameraService();
  final TtsService _ttsService = TtsService();
  String _colorName = '';
  List<int> _rgb = [0, 0, 0];
  bool _isLoading = false;
  String _displayText = '';
  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _cameraService.initializeCamera().then((_) {
      if (mounted) setState(() {});
    });
    _ttsService.initializeTts(_showError);
  }

  Future<void> _takePicture() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final image = await _cameraService.takePicture();
      if (image != null) {
        setState(() {
          _colorName = '';
          _rgb = [0, 0, 0];
        });
      } else {
        _showError('ไม่สามารถถ่ายภาพได้');
      }
    } catch (e) {
      _showError('$e');
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final image = await _cameraService.pickImage();
      if (image != null) {
        setState(() {
          _colorName = '';
          _rgb = [0, 0, 0];
        });
      } else {
        _showError('ไม่สามารถเลือกภาพได้');
      }
    } catch (e) {
      _showError('$e');
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getColorAtPosition(Offset localPosition, Size imageSize) async {
    if (_cameraService.image == null) return;

    try {
      final file = File(_cameraService.image!.path);
      final imageBytes = await file.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        _showError('ไม่สามารถโหลดภาพได้');
        return;
      }

      final x = (localPosition.dx / imageSize.width * image.width).round();
      final y = (localPosition.dy / imageSize.height * image.height).round();

      if (x < 0 || x >= image.width || y < 0 || y >= image.height) {
        _showError('แตะนอกขอบเขตของภาพ');
        return;
      }

      final pixel = image.getPixel(x, y);
      final r = pixel[0].toInt();
      final g = pixel[1].toInt();
      final b = pixel[2].toInt();

      setState(() {
        _rgb = [r, g, b];
        _colorName = _getColorNameFromRGB(r, g, b);
        _displayText = 'สี: $_colorName, ค่า RGB: ${_rgb.join(", ")}';
      });

      // ให้ TTS อ่านเฉพาะชื่อสี
      final ttsText = 'สี $_colorName';
      await _ttsService.speakText(ttsText, _showError);
    } catch (e) {
      _showError('เกิดข้อผิดพลาดในการระบุสี: $e');
    }
  }

  String _getColorNameFromRGB(int r, int g, int b) {
    final List<Map<String, dynamic>> colorMap = [
      {'name': 'แดง', 'rgb': [255, 0, 0]},
      {'name': 'แดงเข้ม', 'rgb': [139, 0, 0]},
      {'name': 'เขียว', 'rgb': [0, 255, 0]},
      {'name': 'เขียวเข้ม', 'rgb': [0, 100, 0]},
      {'name': 'น้ำเงิน', 'rgb': [0, 0, 255]},
      {'name': 'น้ำเงินเข้ม', 'rgb': [0, 0, 139]},
      {'name': 'เหลือง', 'rgb': [255, 255, 0]},
      {'name': 'เหลืองเข้ม', 'rgb': [184, 134, 11]},
      {'name': 'ม่วง', 'rgb': [128, 0, 128]},
      {'name': 'ม่วงอ่อน', 'rgb': [186, 85, 211]},
      {'name': 'ส้ม', 'rgb': [255, 165, 0]},
      {'name': 'ส้มเข้ม', 'rgb': [255, 140, 0]},
      {'name': 'ชมพู', 'rgb': [255, 105, 180]},
      {'name': 'ชมพูเข้ม', 'rgb': [199, 21, 133]},
      {'name': 'ฟ้า', 'rgb': [0, 191, 255]},
      {'name': 'ฟ้าเข้ม', 'rgb': [0, 139, 139]},
      {'name': 'น้ำตาล', 'rgb': [139, 69, 19]},
      {'name': 'น้ำตาลเข้ม', 'rgb': [92, 64, 51]},
      {'name': 'เทา', 'rgb': [128, 128, 128]},
      {'name': 'เทาอ่อน', 'rgb': [192, 192, 192]},
      {'name': 'ดำ', 'rgb': [0, 0, 0]},
      {'name': 'ขาว', 'rgb': [255, 255, 255]},
      {'name': 'ครีม', 'rgb': [245, 245, 220]},
      {'name': 'เขียวมะนาว', 'rgb': [50, 205, 50]},
      {'name': 'เขียวมะกอก', 'rgb': [107, 142, 35]},
      {'name': 'เขียวอมฟ้า', 'rgb': [0, 128, 128]},
      {'name': 'ม่วงเข้ม', 'rgb': [75, 0, 130]},
      {'name': 'เบจ', 'rgb': [245, 245, 220]},
      {'name': 'ทอง', 'rgb': [255, 215, 0]},
      {'name': 'เงิน', 'rgb': [192, 192, 192]},
    ];

    double minDistance = double.infinity;
    String closestColor = colorMap[0]['name'];

    for (var color in colorMap) {
      final cr = color['rgb'][0];
      final cg = color['rgb'][1];
      final cb = color['rgb'][2];
      final distance = sqrt(
        pow(r - cr, 2) + pow(g - cg, 2) + pow(b - cb, 2),
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestColor = color['name'];
      }
    }

    return closestColor;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.prompt(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.red[800],
      ),
    );
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraService.controller;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ฟังก์ชันระบุสี',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 6))
          : SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30),

              // --- พรีวิวกล้องเมื่อยังไม่มีภาพ / พรีวิวภาพเมื่อมีภาพแล้ว ---
              if (_cameraService.image != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GestureDetector(
                    onTapDown: (details) {
                      final RenderBox? box =
                      _imageKey.currentContext?.findRenderObject() as RenderBox?;
                      if (box == null) {
                        _showError('ไม่สามารถดึงขนาดวิดเจ็ตได้');
                        return;
                      }
                      final localOffset = box.globalToLocal(details.globalPosition);
                      final imageSize = box.size;
                      _getColorAtPosition(localOffset, imageSize);
                    },
                    child: Image.file(
                      File(_cameraService.image!.path),
                      key: _imageKey,
                      height: 250,
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    height: 250,
                    child: (controller != null && controller.value.isInitialized)
                        ? AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: CameraPreview(controller),
                    )
                        : const Center(child: CircularProgressIndicator(strokeWidth: 6)),
                  ),
                ),

              const SizedBox(height: 30),

              // ข้อความผลลัพธ์สี
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  _colorName.isEmpty
                      ? 'ยังไม่พบสี'
                      : 'สี: $_colorName\nค่า RGB: ${_rgb.join(", ")}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.prompt(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    letterSpacing: 1.2,
                  ),
                  semanticsLabel: _colorName.isEmpty
                      ? 'ยังไม่พบสี'
                      : 'สี: $_colorName, ค่า RGB: ${_rgb.join(", ")}',
                ),
              ),

              const SizedBox(height: 30),

              // ปุ่มถ่ายภาพ
              ElevatedButton(
                onPressed: _cameraService.isCameraInitialized() ? _takePicture : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF055DD1),
                  minimumSize: const Size(250, 80),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  elevation: 5,
                ),
                child: Text(
                  'ถ่ายภาพ',
                  style: GoogleFonts.prompt(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  semanticsLabel: 'ถ่ายภาพ',
                ),
              ),

              const SizedBox(height: 20),

              // ปุ่มเลือกภาพ
              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF055DD1),
                  minimumSize: const Size(250, 80),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  elevation: 5,
                ),
                child: Text(
                  'เลือกภาพ',
                  style: GoogleFonts.prompt(
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  semanticsLabel: 'เลือกภาพ',
                ),
              ),

              const SizedBox(height: 20),

              // ปุ่ม TTS
              ElevatedButton(
                onPressed: _ttsService.isSpeaking
                    ? _ttsService.stopSpeaking
                    : () {
                  if (_colorName.isNotEmpty && _colorName != 'ไม่พบสี') {
                    final textToSpeak =
                        'สี: $_colorName, ค่า RGB: ${_rgb.join(", ")}';
                    _ttsService.speakText(textToSpeak, _showError);
                  } else {
                    _showError('ไม่มีสีให้อ่าน');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  _ttsService.isSpeaking ? const Color(0xFFE5F7FF) : const Color(0xFF9D150B),
                  minimumSize: const Size(250, 80),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  elevation: 5,
                ),
                child: Text(
                  _ttsService.isSpeaking ? 'หยุดเสียง' : 'ฟังซ้ำ',
                  style: GoogleFonts.prompt(
                    fontSize: 26,
                    color: _ttsService.isSpeaking ? const Color(0xFF02037E) : Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  semanticsLabel: _ttsService.isSpeaking ? 'หยุดเสียง' : 'ฟังซ้ำ',
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF15136E),
        child: InkWell(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Mainpage()),
            );
          },
          splashColor: Colors.white.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Center(
              child: Text(
                'ย้อนกลับ',
                style: GoogleFonts.prompt(
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
