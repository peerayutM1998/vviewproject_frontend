import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vviewproject/services/camera_service.dart';
import 'package:vviewproject/services/api_service.dart';
import 'package:vviewproject/mainpage.dart';
import 'package:vviewproject/services/tts_service.dart';
import 'package:camera/camera.dart'; // ✅ เพิ่มเพื่อใช้ CameraPreview

class FaceRecognitionPage extends StatefulWidget {
  const FaceRecognitionPage({super.key});

  @override
  State<FaceRecognitionPage> createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage> {
  final CameraService _cameraService = CameraService();
  final ApiService _apiService = ApiService();
  final TtsService _ttsService = TtsService();
  List<Map<String, dynamic>> _recognizedFaces = [];
  bool _isLoading = false;
  final TextEditingController _nameController = TextEditingController();

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
      final xfile = await _cameraService.takePicture();
      if (xfile != null) {
        final image = File(xfile.path);
        setState(() {});
        _recognizedFaces = await _apiService.sendImageForFaceRecognition(image);

        if (_recognizedFaces.isEmpty) {
          await _ttsService.speakText('ไม่พบใบหน้า', _showError);
          await _showNameInputDialog(image);
        } else {
          final names = _recognizedFaces.map((f) => f['name'] ?? 'ไม่รู้จัก').join(', ');
          await _ttsService.speakText('พบใบหน้า: $names', _showError);

          final hasUnknown = _recognizedFaces.any((f) =>
          ((f['name'] ?? 'unknown').toString().toLowerCase() == 'unknown') ||
              (((f['confidence'] ?? 1.0) as num).toDouble() < 0.75));

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
        setState(() {});
      }
    } catch (e) {
      _showError('เกิดข้อผิดพลาด: $e');
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
      final xfile = await _cameraService.pickImage();
      if (xfile != null) {
        final image = File(xfile.path);
        setState(() {});
        _recognizedFaces = await _apiService.sendImageForFaceRecognition(image);

        if (_recognizedFaces.isEmpty) {
          await _ttsService.speakText('ไม่พบใบหน้า', _showError);
          await _showNameInputDialog(image);
        } else {
          final names = _recognizedFaces.map((f) => f['name'] ?? 'ไม่รู้จัก').join(', ');
          await _ttsService.speakText('พบใบหน้า: $names', _showError);
        }
        setState(() {});
      }
    } catch (e) {
      _showError('เกิดข้อผิดพลาด: $e');
    }
    setState(() {
      _isLoading = false;
    });
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
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _apiService.saveFace(image, name);
      if (response['status'] == 'success') {
        _showError('บันทึกใบหน้าสำเร็จ: $name');
        await _ttsService.speakText('บันทึกใบหน้าสำเร็จ: $name', _showError);
      } else {
        _showError('บันทึกใบหน้าล้มเหลว: ${response['message']}');
      }
    } catch (e) {
      _showError('เกิดข้อผิดพลาดในการบันทึก: $e');
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.prompt(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.red[800],
      ),
    );
  }

  @override
  void dispose() {
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 6))
          : SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 30),

              // ✅ เพิ่มส่วนพรีวิวกล้องก่อนถ่าย
              if (_cameraService.image != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.file(
                    File(_cameraService.image!.path),
                    height: 250,
                    fit: BoxFit.cover,
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

              // ✅ แสดงชื่อที่ตรวจพบ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  _recognizedFaces.isEmpty
                      ? 'ยังไม่พบใบหน้า'
                      : 'ใบหน้าที่จดจำได้: ${_recognizedFaces.map((f) => f['name'] ?? 'ไม่รู้จัก').join(', ')}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.prompt(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _cameraService.isCameraInitialized() ? _takePicture : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF055DD1),
                  minimumSize: const Size(250, 80),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  elevation: 5,
                ),
                child: Text('ถ่ายภาพ',
                    style: GoogleFonts.prompt(
                        fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF055DD1),
                  minimumSize: const Size(250, 80),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  elevation: 5,
                ),
                child: Text('เลือกภาพ',
                    style: GoogleFonts.prompt(
                        fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _ttsService.isSpeaking
                    ? _ttsService.stopSpeaking
                    : () {
                  if (_recognizedFaces.isNotEmpty) {
                    final names = _recognizedFaces
                        .map((f) => f['name'] ?? 'ไม่รู้จัก')
                        .join(', ');
                    _ttsService.speakText('พบใบหน้า: $names', _showError);
                  } else {
                    _showError('ไม่มีใบหน้าให้อ่าน');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _ttsService.isSpeaking
                      ? const Color(0xFFE5F7FF)
                      : const Color(0xFF9D150B),
                  minimumSize: const Size(250, 80),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  elevation: 5,
                ),
                child: Text(
                  _ttsService.isSpeaking ? 'หยุดเสียง' : 'ฟังซ้ำ',
                  style: GoogleFonts.prompt(
                    fontSize: 26,
                    color: _ttsService.isSpeaking
                        ? const Color(0xFF02037E)
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
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
              child: Text('ย้อนกลับ',
                  style: GoogleFonts.prompt(
                      fontSize: 28, color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }
}
