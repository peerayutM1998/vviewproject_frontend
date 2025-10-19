import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:vviewproject/constants.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  Future<String> sendImageForTextExtraction(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(textApiUrl));
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType(
              'image', imageFile.path.endsWith('.png') ? 'png' : 'jpeg'),
        ),
      );
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);
        return jsonResponse['extracted_text'] ?? 'ไม่พบข้อความ';
      } else {
        throw Exception('API ผิดพลาด: รหัสสถานะ ${response.statusCode}');
      }
    } catch (e) {
      print("Text Extraction API Error: $e");
      throw Exception('เกิดข้อผิดพลาดในการส่งภาพไป API: $e');
    }
  }

  Future<List<Map<String, dynamic>>> sendImageForFaceRecognition(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(faceApiUrl));
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType('image', imageFile.path.endsWith('.png') ? 'png' : 'jpeg'),
        ),
      );
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);
        print('Face recognition response: $jsonResponse'); // เพิ่ม log เพื่อดีบัก
        return List<Map<String, dynamic>>.from(jsonResponse['recognized_faces'] ?? []);
      } else {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);
        throw Exception('API ผิดพลาด: รหัสสถานะ ${response.statusCode}, detail: ${jsonResponse['detail'] ?? 'No detail'}');
      }
    } catch (e) {
      print("Face Recognition API Error: $e");
      throw Exception('เกิดข้อผิดพลาดในการส่งภาพไป API: $e');
    }
  }

  Future<Map<String, dynamic>> sendImageForBanknoteDetection(
      File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(banknoteApiUrl));
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType(
              'image', imageFile.path.endsWith('.png') ? 'png' : 'jpeg'),
        ),
      );
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);
        return {
          'banknotes': Map<String, int>.from(jsonResponse['banknotes'] ?? {}),
          'total_value': jsonResponse['total_value'] ?? 0,
        };
      } else {
        throw Exception('API ผิดพลาด: รหัสสถานะ ${response.statusCode}');
      }
    } catch (e) {
      print("Banknote Detection API Error: $e");
      throw Exception('เกิดข้อผิดพลาดในการส่งภาพไป API: $e');
    }
  }

  Future<Map<String, dynamic>> sendImageForColorIdentification(
      File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(colorApiUrl));
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType(
              'image', imageFile.path.endsWith('.png') ? 'png' : 'jpeg'),
        ),
      );
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);
        return {
          'color_name': jsonResponse['color_name'] ?? 'ไม่พบสี',
          'rgb': List<int>.from(jsonResponse['rgb'] ?? [0, 0, 0]),
        };
      } else {
        throw Exception('API ผิดพลาด: รหัสสถานะ ${response.statusCode}');
      }
    } catch (e) {
      print("Color Identification API Error: $e");
      throw Exception('เกิดข้อผิดพลาดในการส่งภาพไป API: $e');
    }
  }

  Future<Map<String, dynamic>> sendImageForObjectDetectionAndDistance(
      File imageFile) async {
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse(objectDetectionApiUrl));
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType(
              'image', imageFile.path.endsWith('.png') ? 'png' : 'jpeg'),
        ),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        // อ่าน JSON จาก response body
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);

        // ดึงข้อมูลวัตถุและชื่อไฟล์ภาพ
        final detectedObjects = List<Map<String, dynamic>>.from(
            jsonResponse['objects'] ?? []);
        final savedImageFilename = jsonResponse['saved_image_filename'] as String? ??
            '';

        // ส่งคืนข้อมูลวัตถุและชื่อไฟล์ภาพ
        return {
          'objects': detectedObjects,
          'saved_image_filename': savedImageFilename,
        };
      } else {
        throw Exception('API ผิดพลาด: รหัสสถานะ ${response.statusCode}');
      }
    } catch (e) {
      print("Object Detection and Distance API Error: $e");
      throw Exception('เกิดข้อผิดพลาดในการส่งภาพไป API: $e');
    }
  }

  Future<Uint8List?> getImageFromApi(String filename) async {
    try {
      final response = await http.get(Uri.parse('$getImageApiUrl$filename'));

      if (response.statusCode == 200) {
        // อ่าน JSON จาก response body
        final jsonResponse = jsonDecode(response.body);

        // ดึงข้อมูลภาพในรูปแบบ base64
        final imageBase64 = jsonResponse['image'] as String?;
        if (imageBase64 == null ||
            !imageBase64.startsWith('data:image/jpeg;base64,')) {
          throw Exception('ไม่พบข้อมูลภาพใน response หรือรูปแบบไม่ถูกต้อง');
        }

        // แยกส่วน base64 ออกจาก prefix (data:image/jpeg;base64,)
        final base64String = imageBase64.split(',')[1];
        // ถอดรหัส base64 เป็น Uint8List
        final imageBytes = base64Decode(base64String);

        return imageBytes;
      } else {
        throw Exception('API ผิดพลาด: รหัสสถานะ ${response.statusCode}');
      }
    } catch (e) {
      print("Get Image API Error: $e");
      throw Exception('เกิดข้อผิดพลาดในการเรียกภาพจาก API: $e');
    }
  }
  Future<Map<String, dynamic>> saveFace(File image, String name) async {
    try {
      if (!await image.exists()) {
        throw Exception('Image file does not exist: ${image.path}');
      }
      print('Sending save-face request: path=${image.path}, name=$name, exists=${await image.exists()}');
      var request = http.MultipartRequest('POST', Uri.parse('$saveFaceApiUrl')); // ใช้ saveFaceApiUrl
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          image.path,
          contentType: MediaType('image', image.path.endsWith('.png') ? 'png' : 'jpeg'),
        ),
      );
      request.fields['name'] = name;
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonData = jsonDecode(responseData);
      print('Save-face response: status=${response.statusCode}, data=$jsonData');
      if (response.statusCode == 200) {
        return {'status': 'success', 'message': jsonData['message']};
      } else {
        return {'status': 'error', 'message': jsonData['message'] ?? 'Failed to save face'};
      }
    } catch (e) {
      print('Error in saveFace: $e');
      throw Exception('Error saving face: $e');
    }
  }
}
