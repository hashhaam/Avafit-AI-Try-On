import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../config/api_config.dart';
import '../../utils/colors.dart';
import '../../routes/app_routes.dart';
import '../../data/brands.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../common/webview_screen.dart';
import '../search/search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _currentUser;
  bool _isLoading = true;

  File? _selectedImage;
  Uint8List? _avatarBytes;
  bool _isGeneratingAvatar = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await FirestoreService.getUser(user.uid);
        if (mounted) {
          setState(() {
            _currentUser = userData;
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  // ---------------- IMAGE PICK ----------------
  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _avatarBytes = null;
      });
    }
  }

  // ---------------- API CALL ----------------
  Future<void> _generateAvatar() async {
    if (_selectedImage == null) return;

    setState(() => _isGeneratingAvatar = true);

    try {
      final uri = Uri.parse(ApiConfig.generateAvatarUrl);

      final request = http.MultipartRequest('POST', uri);

      request.headers['x-client'] = 'flutter-android';

      final file = await http.MultipartFile.fromPath(
        'file',
        _selectedImage!.path,
        filename: 'avatar.jpg',
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(file);

      final response = await request.send();

      if (response.statusCode == 200) {
        final bytes = await response.stream.toBytes();
        setState(() {
          _avatarBytes = bytes;
        });
      } else {
        final err = await response.stream.bytesToString();
        _showError('Avatar generation failed: ${response.statusCode}');
        debugPrint(err);
      }
    } catch (e, s) {
      debugPrint('UPLOAD ERROR: $e');
      debugPrintStack(stackTrace: s);
      _showError('Server not reachable');
    }

    setState(() => _isGeneratingAvatar = false);
  }

  //-----METHOD TO SHOW ERROR MESSAGES IN SNACKBAR----------
  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildGreeting(),
              const SizedBox(height: 32),

              // ================= AVATAR SECTION =================
              const Text(
                'AI Avatar Generator',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),

              _buildAvatarCard(),

              const SizedBox(height: 40),

              // ================= BRANDS =================
              const Text(
                'Top Brands',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              _buildBrandsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- COMPONENTS ----------------

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.settingsProfile),
          child: CircleAvatar(
            radius: 22,
            backgroundImage: _currentUser?.photoUrl != null
                ? NetworkImage(_currentUser!.photoUrl!)
                : null,
            child: _currentUser?.photoUrl == null
                ? const Icon(Icons.person)
                : null,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    if (_isLoading) {
      return const CircularProgressIndicator(strokeWidth: 2);
    }
    return Text(
      'Hello, ${_currentUser?.name ?? "User"}!',
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
    );
  }

  Widget _buildAvatarCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20),
        ],
      ),
      child: Column(
        children: [
          if (_avatarBytes != null)
            Image.memory(_avatarBytes!, height: 220)
          else if (_selectedImage != null)
            Image.file(_selectedImage!, height: 220)
          else
            const Icon(Icons.person_outline, size: 120, color: Colors.grey),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text("Camera"),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo),
                label: const Text("Gallery"),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedImage == null || _isGeneratingAvatar
                  ? null
                  : _generateAvatar,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.primaryGradient.colors.first,
              ),
              child: _isGeneratingAvatar
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Generate Avatar"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: brands.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (_, index) {
        final brand = brands[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  WebViewScreen(title: brand.name, url: brand.websiteUrl),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(brand.imagePath),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    brand.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
