import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vviewproject/services/camera_service.dart';
import 'package:vviewproject/services/api_service.dart';
import 'package:vviewproject/services/tts_service.dart';
import 'package:vviewproject/mainpage.dart';
import 'package:camera/camera.dart';

class BanknotePage extends StatefulWidget {
  const BanknotePage({super.key});

  @override
  State<BanknotePage> createState() => _BanknotePageState();
}

class _BanknotePageState extends State<BanknotePage> with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final ApiService _apiService = ApiService();
  final TtsService _ttsService = TtsService();

  Map<String, int> _banknotes = {};
  int _totalValue = 0;

  bool _isLoading = false;   // โหลดไฟล์จากแกลเลอรี/เตรียมกล้อง
  bool _processing = false;  // กำลังส่งเข้าระบบตรวจจับธนบัตร

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

  // ---------- Helper: พูดสั้น ๆ ----------
  Future<void> _announce(String text) async {
    try {
      await _ttsService.speakText(text, _showError);
    } catch (_) {}
  }

  // ---------- Actions ----------
  Future<void> _capture() async {
    if (!_cameraService.isCameraInitialized()) return;
    try {
      final img = await _cameraService.takePicture();
      if (img != null && mounted) setState(() {}); // เข้าสู่โหมดพรีวิวภาพ
    } catch (e) {
      _showError('$e');
    }
  }

  Future<void> _confirmAndDetect() async {
    final img = _cameraService.image;
    if (img == null) return;

    setState(() {
      _processing = true;
      _banknotes = {};
      _totalValue = 0;
    });

    try {
      final result = await _apiService.sendImageForBanknoteDetection(File(img.path));
      setState(() {
        _banknotes = Map<String, int>.from(result['banknotes'] ?? {});
        _totalValue = (result['total_value'] ?? 0) as int;
      });

      if (_banknotes.isNotEmpty) {
        final banknoteText = _banknotes.entries.map((e) => '${e.key} บาท ${e.value} ใบ').join(', ');
        final textToSpeak = 'พบธนบัตร: $banknoteText, รวมทั้งหมด $_totalValue บาท';
        await _ttsService.speakText(textToSpeak, _showError);
      } else {
        _showError('ไม่พบธนบัตรในภาพ');
      }
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _pickImage() async {
    setState(() => _isLoading = true);
    try {
      final image = await _cameraService.pickImage();
      if (image != null && mounted) setState(() {}); // ไปโหมดพรีวิวภาพ
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _retake() {
    _cameraService.clearImage();
    setState(() {
      _banknotes = {};
      _totalValue = 0;
    });
  }

  void _speakAgain() {
    if (_banknotes.isEmpty) {
      _showError('ไม่มีธนบัตรให้อ่าน');
      return;
    }
    final banknoteText = _banknotes.entries.map((e) => '${e.key} บาท ${e.value} ใบ').join(', ');
    final textToSpeak = 'พบธนบัตร: $banknoteText, รวมทั้งหมด $_totalValue บาท';
    _ttsService.speakText(textToSpeak, _showError);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.prompt(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600),
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
          'ฟังก์ชันธนบัตร',
          style: GoogleFonts.prompt(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
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
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => Mainpage()));
          },
          splashColor: Colors.white.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Center(
              child: Text(
                'ย้อนกลับ',
                style: GoogleFonts.prompt(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w600, letterSpacing: 1.1),
                semanticsLabel: 'ย้อนกลับ',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(CameraController? controller) {
    // โหมด 1: ยังไม่มีรูป -> กล้องสด + แถบควบคุมแบบ ReadTextPage
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
          // แถบควบคุมล่าง (สลับกล้อง / ถ่าย / แฟลช) + เสียง
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
                // ปุ่มชัตเตอร์แบบวงกลม มีข้อความ "ถ่าย"
                SizedBox(
                  width: 84,
                  height: 84,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _announce('ถ่ายภาพ');
                      await _capture();
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

    // โหมด 2: มีรูปแล้ว -> แสดงพรีวิวเพื่อยืนยัน + ผลลัพธ์
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
                  onPressed: _processing ? null : _confirmAndDetect,
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
        if (_banknotes.isNotEmpty || _totalValue > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Text(
              'ธนบัตร: ${_banknotes.entries.map((e) => "${e.key} บาท: ${e.value} ใบ").join(", ")}\nรวม: $_totalValue บาท',
              textAlign: TextAlign.center,
              style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: ElevatedButton(
            onPressed: _ttsService.isSpeaking ? _ttsService.stopSpeaking : _speakAgain,
            style: ElevatedButton.styleFrom(
              backgroundColor: _ttsService.isSpeaking ? const Color(0xFFE5F7FF) : const Color(0xFF9D150B),
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
