import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class AvatarService {
  // API URL from centralized config
  static String get _baseUrl => ApiConfig.generateAvatarUrl;

  static Future<Uint8List> generateAvatar(File imageFile) async {
    final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));

    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final response = await request.send();

    if (response.statusCode == 200) {
      return await response.stream.toBytes();
    } else {
      throw Exception('Failed to generate avatar');
    }
  }
}
