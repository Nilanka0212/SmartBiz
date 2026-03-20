import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2/SmartBiz/api';

  // ── Register ──
  static Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String nic,
    required String password,
    required String shopCategory,
    required String shopLocation,
    String? shopName,
    String? language,
    Uint8List? profilePhotoBytes,
    String? profilePhotoName,
    Uint8List? shopImageBytes,
    String? shopImageName,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/register.php'),
      );

      // Text fields
      request.fields['name']          = name;
      request.fields['phone']         = phone;
      request.fields['nic']           = nic;
      request.fields['password']      = password;
      request.fields['shop_category'] = shopCategory;
      request.fields['shop_location'] = shopLocation;
      request.fields['language']      = language ?? 'english';
      if (shopName != null && shopName.isNotEmpty) {
        request.fields['shop_name'] = shopName;
      }

      // Profile photo
      if (profilePhotoBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'profile_photo',
          profilePhotoBytes,
          filename: profilePhotoName ?? 'profile.jpg',
        ));
      }

      // Shop image
      if (shopImageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'shop_image',
          shopImageBytes,
          filename: shopImageName ?? 'shop.jpg',
        ));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      return {
        'success': response.statusCode == 200 || response.statusCode == 201,
        'data': data,
      };
    } catch (e) {
      return {
        'success': false,
        'data': {'message': 'Connection error: $e'},
      };
    }
  }

  // ── Login ──
  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone':    phone,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data,
      };
    } catch (e) {
      return {
        'success': false,
        'data': {'message': 'Connection error: $e'},
      };
    }
  }
}