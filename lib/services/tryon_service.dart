import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';

class TryOnService {
  /// Perform virtual try-on
  ///
  /// Sends person image and garment ID to backend
  /// Returns Cloudinary URL of the result image
  ///
  /// Throws Exception on error
  static Future<String?> performTryOn({
    required File personImage,
    required String garmentId,
  }) async {
    try {
      print('🎨 Starting virtual try-on...');
      print('   Person image: ${personImage.path}');
      print('   Garment ID: $garmentId');

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/tryon'),
      );

      // Add person image
      var multipartFile = await http.MultipartFile.fromPath(
        'person_image',
        personImage.path,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);

      // Add garment ID
      request.fields['garment_id'] = garmentId;

      print('🔄 Sending request to backend...');
      print('   This may take 1-2 minutes...');

      // Send request with 180 second timeout
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 180),
        onTimeout: () {
          throw Exception('Request timed out. Please try again.');
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      print('📥 Response received: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final resultUrl = data['result_url'] as String?;

        if (resultUrl != null) {
          print('✅ Try-on successful!');
          print('   Result URL: $resultUrl');
          return resultUrl;
        } else {
          throw Exception('No result URL in response');
        }
      } else {
        print('❌ Try-on failed: ${response.statusCode}');
        print('   Response: ${response.body}');

        // Try to parse error message
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['detail'] ?? 'Unknown error';
          throw Exception(errorMessage);
        } catch (_) {
          throw Exception('Try-on failed: ${response.statusCode}');
        }
      }
    } on TimeoutException {
      print('⏱️  Request timed out');
      throw Exception(
        'Request timed out. The AI is taking longer than expected. Please try again.',
      );
    } catch (e) {
      print('❌ Error in performTryOn: $e');
      rethrow;
    }
  }

  /// Get list of available garments
  ///
  /// Returns list of garment maps with id, name, category, brand, price, thumbnail_url
  static Future<List<Map<String, dynamic>>> getGarments() async {
    try {
      print('📦 Fetching garments from backend...');

      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/garments'))
          .timeout(const Duration(seconds: 30));

      print('📥 Response received: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['garments'] != null) {
          final garmentsList = data['garments'] as List;
          final garments = garmentsList
              .map((item) => item as Map<String, dynamic>)
              .toList();

          print('✅ Loaded ${garments.length} garments');
          return garments;
        } else {
          print('⚠️  No garments found in response');
          return [];
        }
      } else {
        print('❌ Failed to load garments: ${response.statusCode}');
        throw Exception('Failed to load garments: ${response.statusCode}');
      }
    } on TimeoutException {
      print('⏱️  Request timed out');
      throw Exception('Request timed out. Please check your connection.');
    } catch (e) {
      print('❌ Error in getGarments: $e');
      rethrow;
    }
  }
}
