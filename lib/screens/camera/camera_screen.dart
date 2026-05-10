import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../tryon/tryon_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (picked != null && mounted) {
        final File imageFile = File(picked.path);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TryOnScreen(personImage: imageFile),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C6FCD), Color(0xFF6B8EE8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(Icons.camera_alt, color: Colors.white, size: 64),
              ),
              const SizedBox(height: 48),
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C6FCD),
                      shape: StadiumBorder(),
                    ),
                    child: Text(
                      'Take Photo',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFF7C6FCD), width: 2),
                      shape: StadiumBorder(),
                    ),
                    child: Text(
                      'Upload Photo',
                      style: TextStyle(color: Color(0xFF7C6FCD), fontSize: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
