import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vviewproject/services/camera_service.dart';
import 'package:vviewproject/services/api_service.dart';
import 'package:vviewproject/mainpage.dart';
import 'package:vviewproject/services/tts_service.dart';
import 'package:camera/camera.dart';

class FaceRecognitionPage extends StatefulWidget {
  const FaceRecognitionPage({super.key});

  @override
  State<FaceRecognitionPage> createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage>
    with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final ApiService _apiService = ApiService();
  final TtsService _ttsService = TtsService();

  final TextEditingController _nameController = TextEditingController();
  List<Map<String, dynamic>> _recognizedFaces = [];

  bool _isLoading = false;   // โหลดจากแกลเลอรี/เตรียมกล้อง
  bool _processing = false;  // กำลังส่ง API/พูด/ป้องกันกดซ้ำ

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

  void _resetResult() {
    setState(() {
      _recognizedFaces = [];
    });
  }

  // ---------- Actions ----------
  Future<void> _capture() async {
    if (!_cameraService.isCameraInitialized()) return;
    setState(() => _isLoading = true);
    try {
      final xfile = await _cameraService.takePicture();
      if (xfile != null) {
        _resetResult();
        if (mounted) setState(() {}); // เข้าสู่โหมดพรีวิวภาพ
      } else {
        _showError('ไม่สามารถถ่ายภาพได้');
      }
    } catch (e) {
      _showError('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    setState(() => _isLoading = true);
    try {
      final xfile = await _cameraService.pickImage();
      if (xfile != null) {
        _resetResult();
        if (mounted) setState(() {}); // เข้าสู่โหมดพรีวิวภาพ
      } else {
        _showError('ไม่สามารถเลือกภาพได้');
      }
    } catch (e) {
      _showError('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _retake() {
    _cameraService.clearImage();
    _resetResult();
    setState(() {});
  }

  Future<void> _confirmAndRecognize() async {
    if (_processing) return;
    final xfile = _cameraService.image;
    if (xfile == null) return;

    setState(() => _processing = true);
    try {
      final image = File(xfile.path);
      _recognizedFaces = await _apiService.sendImageForFaceRecognition(image);
      setState(() {});

      if (_recognizedFaces.isEmpty) {
        await _announce('ไม่พบใบหน้า');
        await _showNameInputDialog(image);
      } else {
        final names = _recognizedFaces.map((f) => f['name'] ?? 'ไม่รู้จัก').join(', ');
        await _announce('พบใบหน้า: $names');

        // ตรวจว่ามี unknown หรือความมั่นใจต่ำกว่าเกณฑ์ไหม
        final hasUnknown = _recognizedFaces.any((f) {
          final name = (f['name'] ?? 'unknown').toString().toLowerCase();
          final conf = ((f['confidence'] ?? 1.0) as num).toDouble();
          return name == 'unknown' || conf < 0.75;
        });

        if (hasUnknown) {
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('ไม่รู้จักบุคคลนี้',
                  style: GoogleFonts.prompt(fontSize: 22, fontWeight: FontWeight.bold)),
              content: Text('ต้องการบันทึกชื่อไว้หรือไม่?',
                  style: GoogleFonts.prompt(fontSize: 18)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('ไม่บันทึก', style: GoogleFonts.prompt())),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text('บันทึก', style: GoogleFonts.prompt())),
              ],
            ),
          ) ??
              false;

          if (ok) {
            await _showNameInputDialog(image);
          }
        }
      }
    } catch (e) {
      _showError('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _showNameInputDialog(File image) async {
    _nameController.clear();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ไม่พบใบหน้า',
            style: GoogleFonts.prompt(fontSize: 24, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('กรุณาตั้งชื่อสำหรับบันทึกใบหน้านี้',
                style: GoogleFonts.prompt(fontSize: 18)),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'ชื่อ',
                labelStyle: GoogleFonts.prompt(),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก', style: GoogleFonts.prompt(fontSize: 18)),
          ),
          TextButton(
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                Navigator.pop(context);
                await _saveFace(image, _nameController.text);
              } else {
                _showError('กรุณาใส่ชื่อ');
              }
            },
            child: Text('บันทึก', style: GoogleFonts.prompt(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveFace(File image, String name) async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.saveFace(image, name);
      if ((response['status'] ?? '') == 'success') {
        _showError('บันทึกใบหน้าสำเร็จ: $name');
        await _announce('บันทึกใบหน้าสำเร็จ: $name');
      } else {
        _showError('บันทึกใบหน้าล้มเหลว: ${response['message']}');
      }
    } catch (e) {
      _showError('เกิดข้อผิดพลาดในการบันทึก: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraService.controller;

    return Scaffold(
      appBar: AppBar(
        title: Text('ฟังก์ชันจดจำใบหน้า',
            style: GoogleFonts.prompt(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
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
              child: Text('ย้อนกลับ',
                  style: GoogleFonts.prompt(
                      fontSize: 28, color: Colors.white, fontWeight: FontWeight.w600)),
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

    // โหมด 2: มีรูปแล้ว -> พรีวิว + ปุ่ม ถ่ายใหม่/ใช้ภาพนี้ + แสดงผลชื่อที่พบ
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
                  onPressed: _processing ? null : _confirmAndRecognize,
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
        // ผลลัพธ์ชื่อที่พบ
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Text(
            _recognizedFaces.isEmpty
                ? 'ยังไม่พบใบหน้า'
                : 'ใบหน้าที่จดจำได้: ${_recognizedFaces.map((f) => f['name'] ?? 'ไม่รู้จัก').join(', ')}',
            textAlign: TextAlign.center,
            style: GoogleFonts.prompt(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // ปุ่มฟังซ้ำ/หยุดเสียง
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: ElevatedButton(
            onPressed: _ttsService.isSpeaking
                ? _ttsService.stopSpeaking
                : () {
              if (_recognizedFaces.isNotEmpty) {
                final names =
                _recognizedFaces.map((f) => f['name'] ?? 'ไม่รู้จัก').join(', ');
                _ttsService.speakText('พบใบหน้า: $names', _showError);
              } else {
                _showError('ไม่มีใบหน้าให้อ่าน');
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
