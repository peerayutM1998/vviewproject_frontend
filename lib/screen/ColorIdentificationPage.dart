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

class _ColorIdentificationPageState extends State<ColorIdentificationPage>
    with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final TtsService _ttsService = TtsService();

  String _colorName = '';
  List<int> _rgb = [0, 0, 0];

  bool _isLoading = false;      // โหลดจากแกลเลอรี/เตรียมกล้อง
  bool _processing = false;     // กันกดซ้ำขณะพูด/ประมวลผลสั้น ๆ
  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cameraService.initializeCamera().then((_) {
      if (mounted) setState(() {});
    });
    _ttsService.initializeTts(_showError);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _cameraService.initializeCamera().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  // ---------- Helpers ----------
  Future<void> _announce(String text) async {
    try {
      await _ttsService.speakText(text, _showError);
    } catch (_) {}
  }

  void _resetColor() {
    setState(() {
      _colorName = '';
      _rgb = [0, 0, 0];
    });
  }

  // ---------- Actions ----------
  Future<void> _takePicture() async {
    if (!_cameraService.isCameraInitialized()) return;
    setState(() => _isLoading = true);
    try {
      final image = await _cameraService.takePicture();
      if (image != null) {
        _resetColor();
        if (mounted) setState(() {});
      } else {
        _showError('ไม่สามารถถ่ายภาพได้');
      }
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    setState(() => _isLoading = true);
    try {
      final image = await _cameraService.pickImage();
      if (image != null) {
        _resetColor();
        if (mounted) setState(() {});
      } else {
        _showError('ไม่สามารถเลือกภาพได้');
      }
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _retake() {
    _cameraService.clearImage();
    _resetColor();
    setState(() {});
  }

  Future<void> _confirmImage() async {
    // ไม่มีการประมวลผลหนัก แค่ยืนยันและแนะนำการใช้งานด้วยเสียง
    if (_processing) return;
    setState(() => _processing = true);
    try {
      await _announce('แตะตำแหน่งบนภาพเพื่อระบุสี');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _getColorAtPosition(Offset localPosition, Size imageSize) async {
    if (_cameraService.image == null || _processing) return;
    setState(() => _processing = true);

    try {
      final file = File(_cameraService.image!.path);
      final imageBytes = await file.readAsBytes();
      final decoded = img.decodeImage(imageBytes);

      if (decoded == null) {
        _showError('ไม่สามารถโหลดภาพได้');
        return;
      }

      final x = (localPosition.dx / imageSize.width * decoded.width).round();
      final y = (localPosition.dy / imageSize.height * decoded.height).round();

      if (x < 0 || x >= decoded.width || y < 0 || y >= decoded.height) {
        _showError('แตะนอกขอบเขตของภาพ');
        return;
      }

      final pixel = decoded.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      setState(() {
        _rgb = [r, g, b];
        _colorName = _getColorNameFromRGB(r, g, b);
      });



      // พูดเฉพาะชื่อสี
      await _announce('สี $_colorName');
    } catch (e) {
      _showError('เกิดข้อผิดพลาดในการระบุสี: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
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
    WidgetsBinding.instance.removeObserver(this);
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
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 6))
            : _buildBody(controller),
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

  Widget _buildBody(CameraController? controller) {
    // โหมด 1: ยังไม่มีรูป -> กล้องสด + แถบควบคุม (สลับกล้อง/ถ่าย/แฟลช) + ปุ่มเลือกแกลเลอรี
    if (_cameraService.image == null) {
      if (controller == null || !controller.value.isInitialized) {
        return const Center(child: CircularProgressIndicator(strokeWidth: 6));
      }
      return Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: CameraPreview(controller),
                ),
                // overlay เบา ๆ
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // แถบควบคุมล่าง
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // สลับกล้อง
                IconButton(
                  iconSize: 36,
                  tooltip: 'สลับกล้อง',
                  onPressed: () async {
                    await _announce('สลับกล้อง');
                    await _cameraService.switchCamera();
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.cameraswitch),
                ),
                // ปุ่มชัตเตอร์วงกลม "ถ่าย"
                SizedBox(
                  width: 84,
                  height: 84,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _announce('ถ่ายภาพ');
                      await _takePicture();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF15136E),
                      shape: const CircleBorder(),
                      elevation: 3,
                      side: const BorderSide(color: Colors.white, width: 4),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      'ถ่าย',
                      style: GoogleFonts.prompt(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                      semanticsLabel: 'ถ่าย',
                    ),
                  ),
                ),
                // แฟลช
                IconButton(
                  iconSize: 32,
                  tooltip: 'แฟลช',
                  onPressed: () async {
                    await _announce('แฟลช');
                    await _cameraService.toggleFlash();
                    if (mounted) setState(() {});
                  },
                  icon: Icon(
                    _cameraService.isFlashOn ? Icons.flash_on : Icons.flash_off,
                  ),
                ),
              ],
            ),
          ),
          // ปุ่มเลือกจากแกลเลอรี
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton(
              onPressed: _pickImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF055DD1),
                minimumSize: const Size(240, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                'เลือกภาพจากแกลเลอรี',
                style: GoogleFonts.prompt(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // โหมด 2: มีรูปแล้ว -> พรีวิว + ปุ่ม ถ่ายใหม่/ใช้ภาพนี้ + แตะภาพเพื่อระบุสี
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
          ),
        ),
        if (_processing)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: CircularProgressIndicator(strokeWidth: 5),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _processing ? null : _retake,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 56),
                    side: const BorderSide(color: Color(0xFF055DD1), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    'ถ่ายใหม่',
                    style: GoogleFonts.prompt(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF055DD1),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _processing ? null : _confirmImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF055DD1),
                    minimumSize: const Size(0, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 2,
                  ),
                  child: Text(
                    'ใช้ภาพนี้',
                    style: GoogleFonts.prompt(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // แสดงผลลัพธ์สี
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Text(
            _colorName.isEmpty
                ? 'ยังไม่พบสี'
                : 'สี: $_colorName\nค่า RGB: ${_rgb.join(", ")}',
            textAlign: TextAlign.center,
            style: GoogleFonts.prompt(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // ปุ่มฟังซ้ำ/หยุดเสียง (ออปชัน)
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: ElevatedButton(
            onPressed: _ttsService.isSpeaking
                ? _ttsService.stopSpeaking
                : () {
              if (_colorName.isNotEmpty && _colorName != 'ไม่พบสี') {
                final textToSpeak = 'สี: $_colorName, ค่า อาร์จีบี: ${_rgb.join(", ")}';
                _ttsService.speakText(textToSpeak, _showError);
              } else {
                _showError('ไม่มีสีให้อ่าน');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
              _ttsService.isSpeaking ? const Color(0xFFE5F7FF) : const Color(0xFF9D150B),
              minimumSize: const Size(250, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 2,
            ),
            child: Text(
              _ttsService.isSpeaking ? 'หยุดเสียง' : 'ฟังซ้ำ',
              style: GoogleFonts.prompt(
                fontSize: 20,
                color: _ttsService.isSpeaking ? const Color(0xFF02037E) : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
