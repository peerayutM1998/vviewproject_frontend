import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vviewproject/services/camera_service.dart';
import 'package:vviewproject/services/api_service.dart';
import 'package:vviewproject/mainpage.dart';
import 'package:vviewproject/services/tts_service.dart';
import 'package:camera/camera.dart';

class ObstacleDetectionPage extends StatefulWidget {
  const ObstacleDetectionPage({super.key});

  @override
  State<ObstacleDetectionPage> createState() => _ObstacleDetectionPageState();
}

class _ObstacleDetectionPageState extends State<ObstacleDetectionPage>
    with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  final ApiService _apiService = ApiService();
  final TtsService _ttsService = TtsService();

  List<Map<String, dynamic>> _detectedObjects = [];
  Uint8List? _imageBytes;                 // ภาพตีกรอบที่ได้จาก API (ถ้ามี)
  String _obstacleText = '';

  bool _isLoading = false;                // โหลดจากแกลเลอรี/เตรียมกล้อง
  bool _processing = false;               // ส่ง API / กันกดซ้ำ

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
      _detectedObjects = [];
      _imageBytes = null;
      _obstacleText = '';
    });
  }

  String _generateObstacleDescription(List<Map<String, dynamic>> objects) {
    if (objects.isEmpty) return 'ไม่พบวัตถุ';
    final descriptions = objects.map((obj) {
      final className = obj['class_name'] ?? 'วัตถุ';
      final distance = obj['distance_meters']?.toString() ?? 'ไม่ทราบ';
      final confidence = ((obj['confidence'] ?? 0.0) * 100).toStringAsFixed(1);
      return '$className อยู่ห่าง $distance เมตร ความมั่นใจ $confidence เปอร์เซ็นต์';
    }).toList();
    return descriptions.join(', ');
  }

  String _generateSpeakText(List<Map<String, dynamic>> objects) {
    if (objects.isEmpty) return 'ไม่พบวัตถุ';
    return objects.map((obj) {
      final className = obj['class_name'] ?? 'วัตถุ';
      final distance = obj['distance_meters']?.toString() ?? 'ไม่ทราบ';
      return '$className อยู่ห่าง $distance เมตร';
    }).join(', ');
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

  // ---------- Actions ----------
  Future<void> _capture() async {
    if (!_cameraService.isCameraInitialized()) return;
    setState(() => _isLoading = true);
    try {
      final xfile = await _cameraService.takePicture();
      if (xfile != null) {
        _resetResult();
        if (mounted) setState(() {}); // เข้าโหมดพรีวิวภาพ (ยังไม่เรียก API)
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
      final xfile = await _cameraService.pickImage();
      if (xfile != null) {
        _resetResult();
        if (mounted) setState(() {}); // เข้าโหมดพรีวิวภาพ (ยังไม่เรียก API)
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
    _resetResult();
    setState(() {});
  }

  Future<void> _confirmAndDetect() async {
    if (_processing) return;
    final xfile = _cameraService.image;
    if (xfile == null) return;

    setState(() => _processing = true);
    try {
      final result =
      await _apiService.sendImageForObjectDetectionAndDistance(File(xfile.path));
      final savedImageFilename = (result['saved_image_filename'] ?? '') as String;

      Uint8List? imageBytes;
      if (savedImageFilename.isNotEmpty) {
        imageBytes = await _apiService.getImageFromApi(savedImageFilename);
      }

      final objects = List<Map<String, dynamic>>.from(result['objects'] ?? []);
      final displayText = _generateObstacleDescription(objects);
      final speakText = _generateSpeakText(objects);

      setState(() {
        _detectedObjects = objects;
        _imageBytes = imageBytes; // ถ้ามีภาพตีกรอบจากเซิร์ฟเวอร์ จะแสดงแทน
        _obstacleText = displayText;
      });

      await _ttsService.speakText(speakText, _showError);
    } catch (e) {
      _showError('$e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
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
    // โหมด 1: ยังไม่มีภาพ -> กล้องสด + แถบควบคุม (สลับกล้อง/ถ่าย/แฟลช) + ปุ่มเลือกแกลเลอรี
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
                // overlay กรอบบาง ๆ
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
          // แถบควบคุมล่าง (เสียงด้วย)
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

    // โหมด 2: มีภาพแล้ว -> พรีวิว + ปุ่ม ถ่ายใหม่/ใช้ภาพนี้ + (หลังยืนยัน) แสดงผล/พูด
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _imageBytes != null
            // ถ้ามีภาพตีกรอบจาก API ให้แสดงภาพนั้น
                ? Image.memory(
              _imageBytes!,
              fit: BoxFit.contain,
              width: double.infinity,
            )
            // ยังไม่ได้เรียก API → แสดงภาพดิบที่ถ่าย/เลือก
                : Image.file(
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
        // สรุปสิ่งกีดขวาง (หลังเรียก API แล้ว)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Text(
            _obstacleText.isEmpty ? 'ยังไม่พบสิ่งกีดขวาง' : _obstacleText,
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
              final text = _obstacleText.isEmpty
                  ? _generateObstacleDescription(_detectedObjects)
                  : _obstacleText;
              _ttsService.speakText(text, _showError);
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
