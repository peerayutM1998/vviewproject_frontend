// read_text_page.dart
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vviewproject/services/camera_service.dart';
import 'package:vviewproject/services/api_service.dart';
import 'package:vviewproject/mainpage.dart';
import 'package:vviewproject/services/tts_service.dart';

class ReadTextPage extends StatefulWidget {
  const ReadTextPage({super.key});

  @override
  State<ReadTextPage> createState() => _ReadTextPageState();
}

class _ReadTextPageState extends State<ReadTextPage> with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final ApiService _apiService = ApiService();
  final TtsService _ttsService = TtsService();

  String _extractedText = '';
  bool _isLoading = false;
  bool _processingImage = false; // ระหว่างส่ง OCR

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
    // จัดการกล้องเวลาแอปพัก/กลับมา
    final controller = _cameraService.controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _cameraService.initializeCamera().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _capture() async {
    if (!_cameraService.isCameraInitialized()) return;
    try {
      final img = await _cameraService.takePicture();
      if (img != null) {
        setState(() {}); // จะเข้าโหมด "พรีวิวภาพที่ถ่าย" ทันที
      }
    } catch (e) {
      _showError('$e');
    }
  }

  Future<void> _confirmAndProcess() async {
    final img = _cameraService.image;
    if (img == null) return;
    setState(() {
      _processingImage = true;
      _extractedText = '';
    });
    try {
      final text = await _apiService.sendImageForTextExtraction(File(img.path));
      _extractedText = text;
      if (_extractedText.isNotEmpty && _extractedText != 'ไม่พบข้อความ') {
        await _ttsService.speakText(_extractedText, _showError);
      }
    } catch (e) {
      _showError('$e');
    } finally {
      setState(() {
        _processingImage = false;
      });
    }
  }

  Future<void> _pickImage() async {
    setState(() => _isLoading = true);
    try {
      final image = await _cameraService.pickImage();
      if (image != null) {
        setState(() {}); // ไปหน้าพรีวิวภาพที่เลือก
      }
    } catch (e) {
      _showError('$e');
    }
    setState(() => _isLoading = false);
  }

  void _retake() {
    _cameraService.clearImage();
    setState(() {});
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
          'ฟังก์ชันอ่านข้อความ',
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
    // โหมด 1: ยังไม่มีรูป -> แสดงพรีวิวกล้องสด
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
                // กล้องสด
                AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: CameraPreview(controller),
                ),
                // เส้นกรอบช่วยเล็ง (overlay เบา ๆ)
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
                  onPressed: () async {
                    await _cameraService.switchCamera();
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.cameraswitch),
                ),
                // ปุ่มชัตเตอร์
                GestureDetector(
                  onTap: _capture,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                  ),
                ),
                // แฟลช
                IconButton(
                  iconSize: 32,
                  onPressed: () async {
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
                style: GoogleFonts.prompt(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    }

    // โหมด 2: มีรูปแล้ว -> แสดงพรีวิวเพื่อยืนยัน
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Image.file(
              File(_cameraService.image!.path),
              fit: BoxFit.contain,
              width: double.infinity,
            ),
          ),
        ),
        if (_processingImage) const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: CircularProgressIndicator(strokeWidth: 5),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _processingImage ? null : _retake,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 56),
                    side: const BorderSide(color: Color(0xFF055DD1), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    'ถ่ายใหม่',
                    style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF055DD1)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _processingImage ? null : _confirmAndProcess,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF055DD1),
                    minimumSize: const Size(0, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 2,
                  ),
                  child: Text(
                    'ใช้ภาพนี้',
                    style: GoogleFonts.prompt(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        // แสดงผลข้อความที่แยกได้
        if (_extractedText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Text(
              'ข้อความที่แยกได้: $_extractedText',
              textAlign: TextAlign.center,
              style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
