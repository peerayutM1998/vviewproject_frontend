import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vviewproject/services/camera_service.dart';
import 'package:vviewproject/services/api_service.dart';
import 'package:vviewproject/mainpage.dart';
import 'package:vviewproject/services/tts_service.dart';
import 'package:camera/camera.dart'; // ✅ ใช้สำหรับ CameraPreview

class ObstacleDetectionPage extends StatefulWidget {
  const ObstacleDetectionPage({super.key});

  @override
  State<ObstacleDetectionPage> createState() => _ObstacleDetectionPageState();
}

class _ObstacleDetectionPageState extends State<ObstacleDetectionPage> {
  final CameraService _cameraService = CameraService();
  final ApiService _apiService = ApiService();
  final TtsService _ttsService = TtsService();
  List<Map<String, dynamic>> _detectedObjects = [];
  Uint8List? _imageBytes;
  String _savedImageFilename = '';
  String _obstacleText = '';
  bool _isLoading = false;

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
        final result = await _apiService.sendImageForObjectDetectionAndDistance(File(image.path));
        final savedImageFilename = result['saved_image_filename'] as String;
        Uint8List? imageBytes;
        if (savedImageFilename.isNotEmpty) {
          imageBytes = await _apiService.getImageFromApi(savedImageFilename);
        }

        setState(() {
          _detectedObjects = List<Map<String, dynamic>>.from(result['objects'] ?? []);
          _savedImageFilename = savedImageFilename;
          _imageBytes = imageBytes;
        });

        if (_detectedObjects.isNotEmpty) {
          final displayText = _generateObstacleDescription(_detectedObjects);
          final speakText = _generateSpeakText(_detectedObjects);
          setState(() {
            _obstacleText = displayText;
          });
          await _ttsService.speakText(speakText, _showError);
        } else {
          setState(() {
            _obstacleText = 'ไม่พบวัตถุ';
          });
          await _ttsService.speakText('ไม่พบวัตถุ', _showError);
        }
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
        final result = await _apiService.sendImageForObjectDetectionAndDistance(File(image.path));
        final savedImageFilename = result['saved_image_filename'] as String;
        Uint8List? imageBytes;
        if (savedImageFilename.isNotEmpty) {
          imageBytes = await _apiService.getImageFromApi(savedImageFilename);
        }

        setState(() {
          _detectedObjects = List<Map<String, dynamic>>.from(result['objects'] ?? []);
          _savedImageFilename = savedImageFilename;
          _imageBytes = imageBytes;
        });

        if (_detectedObjects.isNotEmpty) {
          final displayText = _generateObstacleDescription(_detectedObjects);
          final speakText = _generateSpeakText(_detectedObjects);
          setState(() {
            _obstacleText = displayText;
          });
          await _ttsService.speakText(speakText, _showError);
        } else {
          setState(() {
            _obstacleText = 'ไม่พบวัตถุ';
          });
          await _ttsService.speakText('ไม่พบวัตถุ', _showError);
        }
      }
    } catch (e) {
      _showError('$e');
    }
    setState(() {
      _isLoading = false;
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

  @override
  void dispose() {
    _cameraService.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraService.controller; // ✅ ใช้สำหรับ CameraPreview
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
            : SingleChildScrollView(
          child: Container(
            width: screenWidth,
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.05,
              vertical: 20,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: screenHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // ✅ ถ้ายังไม่มีภาพที่ประมวลผลจาก API ให้แสดงกล้องพรีวิวก่อนถ่าย
                  if (_imageBytes != null)
                    Container(
                      width: screenWidth * 0.9,
                      constraints: BoxConstraints(maxHeight: screenHeight * 0.4),
                      child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                    )
                  else
                    Container(
                      width: screenWidth * 0.9,
                      constraints: BoxConstraints(maxHeight: screenHeight * 0.4),
                      child: (controller != null && controller.value.isInitialized)
                          ? AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: CameraPreview(controller),
                      )
                          : Center(
                        child: Text(
                          'ไม่มีภาพที่เลือก',
                          style: GoogleFonts.prompt(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          semanticsLabel: 'ไม่มีภาพที่เลือก',
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _detectedObjects.isEmpty
                          ? 'ยังไม่พบสิ่งกีดขวาง'
                          : _generateObstacleDescription(_detectedObjects),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.prompt(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        letterSpacing: 1.2,
                      ),
                      semanticsLabel: _detectedObjects.isEmpty
                          ? 'ยังไม่พบสิ่งกีดขวาง'
                          : _generateObstacleDescription(_detectedObjects),
                    ),
                  ),

                  const SizedBox(height: 40),

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
                        letterSpacing: 1.1,
                      ),
                      semanticsLabel: 'เลือกภาพ',
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _ttsService.isSpeaking
                        ? _ttsService.stopSpeaking
                        : () => _ttsService.speakText(
                      _generateObstacleDescription(_detectedObjects),
                      _showError,
                    ),
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

                  const SizedBox(height: 40),
                ],
              ),
            ),
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
