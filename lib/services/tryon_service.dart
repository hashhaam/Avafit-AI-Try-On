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
    // Warm up backend first
    try {
      print('🔥 Warming up backend...');
      await http
          .get(Uri.parse('${ApiConfig.baseUrl}/garments'))
          .timeout(const Duration(seconds: 60));
      print('✅ Backend warmed up');
    } catch (e) {
      print('⚠️  Warm-up failed (continuing anyway): $e');
    }

    // Try up to 2 times (initial + 1 retry)
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        print('🎨 Starting virtual try-on (attempt $attempt/2)...');
        print('   Person image: ${personImage.path}');
        print('   Garment ID: $garmentId');

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiConfig.baseUrl}/tryon'),
        );

        var multipartFile = await http.MultipartFile.fromPath(
          'person_image',
          personImage.path,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);

        request.fields['garment_id'] = garmentId;

        print('🔄 Sending request to backend...');
        print('   This may take 2-4 minutes on first try-on...');

        var streamedResponse = await request.send().timeout(
          const Duration(seconds: 300),
          onTimeout: () {
            throw TimeoutException('Request timed out');
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

          try {
            final errorData = json.decode(response.body);
            final errorMessage = errorData['detail'] ?? 'Unknown error';
            throw Exception(errorMessage);
          } catch (_) {
            throw Exception('Try-on failed: ${response.statusCode}');
          }
        }
      } on SocketException catch (e) {
        print('🔌 Network error on attempt $attempt: $e');
        if (attempt == 1) {
          print('⏳ Waiting 5 seconds before retry...');
          await Future.delayed(const Duration(seconds: 5));
          continue;
        }
        throw Exception(
          'Network connection failed. Please check your internet and try again.',
        );
      } on TimeoutException {
        print('⏱️  Request timed out on attempt $attempt');
        if (attempt == 1) {
          print('⏳ Retrying...');
          await Future.delayed(const Duration(seconds: 5));
          continue;
        }
        throw Exception(
          'AI is taking too long. The free server may be busy. Please try again in a few minutes.',
        );
      } catch (e) {
        print('❌ Error in performTryOn: $e');
        rethrow;
      }
    }

    return null;
  }

  /// Get list of available garments organized by brands
  ///
  /// Returns list of brand maps with id, name, tagline, and garments array
  static Future<List<Map<String, dynamic>>> getGarments() async {
    try {
      print('📦 Fetching garments from backend...');

      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/garments'))
          .timeout(const Duration(seconds: 30));

      print('📥 Response received: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['brands'] != null) {
          final brandsList = data['brands'] as List;
          final brands = brandsList
              .map((item) => item as Map<String, dynamic>)
              .toList();

          print('✅ Loaded ${brands.length} brands');
          return brands;
        } else {
          print('⚠️  No brands found in response');
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

  /// Get flat list of all garments across all brands
  ///
  /// Returns list of garment maps for try-on screen garment selector
  static Future<List<Map<String, dynamic>>> getAllGarmentsFlat() async {
    try {
      print('📦 Fetching all garments (flat)...');

      final brands = await getGarments();
      final List<Map<String, dynamic>> allGarments = [];

      for (var brand in brands) {
        final garments = brand['garments'] as List?;
        if (garments != null) {
          for (var garment in garments) {
            // Add brand info to each garment
            final garmentWithBrand = Map<String, dynamic>.from(garment);
            garmentWithBrand['brand_name'] = brand['name'];
            garmentWithBrand['brand_id'] = brand['id'];
            allGarments.add(garmentWithBrand);
          }
        }
      }

      print('✅ Loaded ${allGarments.length} total garments');
      return allGarments;
    } catch (e) {
      print('❌ Error in getAllGarmentsFlat: $e');
      rethrow;
    }
  }
}
