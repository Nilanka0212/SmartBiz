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
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/login.php'),
    );
    request.fields['phone']    = phone;
    request.fields['password'] = password;

    final response     = await request.send();
    final responseBody = await response.stream.bytesToString();

    // print('Login Response: $responseBody');

    if (responseBody.isEmpty) {
      return {
        'success': false,
        'data': {'message': 'Empty response from server'}
      };
    }

    final data = jsonDecode(responseBody);
    return {
      'success': data['success'] == true,
      'data': data,
    };
  } catch (e) {
    return {
      'success': false,
      'data': {'message': 'Connection error: $e'},
    };
  }
}
  // ── Verify OTP ──
static Future<Map<String, dynamic>> verifyOtp({
  required String ownerId,
  required String otp,
}) async {
  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/verify_otp.php'),
    );
    request.fields['owner_id'] = ownerId;
    request.fields['otp']      = otp;

    final response     = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data         = jsonDecode(responseBody);

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
// ── Forgot Password ──
static Future<Map<String, dynamic>> forgotPassword({
  required String phone,
}) async {
  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/forgot_password.php'),
    );
    request.fields['phone'] = phone;
    final response     = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data         = jsonDecode(responseBody);
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

// ── Reset Password ──
static Future<Map<String, dynamic>> resetPassword({
  required String phone,
  required String otp,
  required String newPassword,
}) async {
  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/reset_password.php'),
    );
    request.fields['phone']        = phone;
    request.fields['otp']          = otp;
    request.fields['new_password'] = newPassword;
    final response     = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data         = jsonDecode(responseBody);
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


// ── Get Products ──
static Future<Map<String, dynamic>> getProducts({
  required String ownerId,
}) async {
  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/products/get_products.php'),
    );
    request.fields['owner_id'] = ownerId;
    final response     = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data         = jsonDecode(responseBody);
    return {'success': data['success'], 'data': data};
  } catch (e) {
    return {
      'success': false,
      'data': {'message': 'Connection error: $e'}
    };
  }
}

// ── Add Product ──
static Future<Map<String, dynamic>> addProduct({
  required String ownerId,
  required String name,
  required String price,
  required String description,
  Uint8List? imageBytes,
  String? imageName,
}) async {
  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/products/add_product.php'),
    );
    request.fields['owner_id']    = ownerId;
    request.fields['name']        = name;
    request.fields['price']       = price;
    request.fields['description'] = description;

    if (imageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: imageName ?? 'product.jpg',
      ));
    }

    final response     = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data         = jsonDecode(responseBody);
    return {
      'success': data['success'] == true,
      'data': data
    };
  } catch (e) {
    return {
      'success': false,
      'data': {'message': 'Connection error: $e'}
    };
  }
}

// ── Update Product ──
static Future<Map<String, dynamic>> updateProduct({
  required String productId,
  required String name,
  required String price,
  required String description,
  Uint8List? imageBytes,
  String? imageName,
}) async {
  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/products/update_product.php'),
    );
    request.fields['product_id']  = productId;
    request.fields['name']        = name;
    request.fields['price']       = price;
    request.fields['description'] = description;

    if (imageBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: imageName ?? 'product.jpg',
      ));
    }

    final response     = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data         = jsonDecode(responseBody);
    return {
      'success': data['success'] == true,
      'data': data
    };
  } catch (e) {
    return {
      'success': false,
      'data': {'message': 'Connection error: $e'}
    };
  }
}

// ── Toggle Product ──
static Future<Map<String, dynamic>> toggleProduct({
  required String productId,
  required bool isActive,
}) async {
  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/products/toggle_product.php'),
    );
    request.fields['product_id'] = productId;
    request.fields['is_active']  = isActive ? '1' : '0';

    final response     = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data         = jsonDecode(responseBody);
    return {
      'success': data['success'] == true,
      'data': data
    };
  } catch (e) {
    return {
      'success': false,
      'data': {'message': 'Connection error: $e'}
    };
  }
}
}