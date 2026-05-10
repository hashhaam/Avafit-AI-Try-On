import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

import '../config/api_config.dart';

class CloudinaryService {
  /// Upload profile photo to Cloudinary via backend
  static Future<String> uploadProfilePhoto(File imageFile) async {
    try {
      print('📤 Uploading profile photo to Cloudinary...');

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/upload-profile-photo'),
      );

      // Add image file with proper content type
      var multipartFile = await http.MultipartFile.fromPath(
        'photo',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      print('🔄 Sending request to backend...');

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final photoUrl = data['photo_url'] as String;

        print('✅ Photo uploaded successfully!');
        print('   URL: $photoUrl');

        return photoUrl;
      } else {
        print('❌ Upload failed: ${response.statusCode}');
        print('   Response: ${response.body}');
        throw Exception(
          'Upload failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error uploading photo: $e');
      rethrow;
    }
  }
}
