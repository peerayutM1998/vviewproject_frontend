// services/camera_service.dart
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class CameraService {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _flashOn = false;

  XFile? _image;

  CameraController? get controller => _cameraController;
  XFile? get image => _image;
  bool get isFlashOn => _flashOn;

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      await _initController(_cameras[_cameraIndex]);
    }
  }

  Future<void> _initController(CameraDescription cam) async {
    _cameraController?.dispose();
    _cameraController = CameraController(
      cam,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await _cameraController!.initialize();
    // ปิดแฟลชเริ่มต้น
    _flashOn = false;
    await _cameraController!.setFlashMode(FlashMode.off);
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _initController(_cameras[_cameraIndex]);
  }

  Future<void> toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    _flashOn = !_flashOn;
    await _cameraController!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
  }

  Future<XFile?> takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _cameraController!.value.isTakingPicture) {
      return null;
    }
    try {
      final XFile image = await _cameraController!.takePicture();
      _image = image;
      return image;
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการถ่ายภาพ: $e');
    }
  }

  Future<XFile?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        _image = image;
        return image;
      }
      return null;
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาดในการเลือกภาพ: $e');
    }
  }

  void clearImage() {
    _image = null;
  }

  void dispose() {
    _cameraController?.dispose();
  }

  bool isCameraInitialized() {
    return _cameraController != null && _cameraController!.value.isInitialized;
  }
}
