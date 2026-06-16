import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../utils/colors.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../services/cloudinary_service.dart';

class SettingsProfileScreen extends StatefulWidget {
  const SettingsProfileScreen({super.key});

  @override
  State<SettingsProfileScreen> createState() => _SettingsProfileScreenState();
}

class _SettingsProfileScreenState extends State<SettingsProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String? _selectedGender;
  final ImagePicker _picker = ImagePicker();

  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final userData = await FirestoreService.getUser(user.uid);

        if (userData != null && mounted) {
          setState(() {
            _currentUser = userData;
            _nameController.text = userData.name;
            _phoneController.text = userData.phone ?? '';
            _ageController.text = userData.age?.toString() ?? '';
            _heightController.text = userData.height != null
                ? userData.height!.toStringAsFixed(0)
                : '';
            _weightController.text = userData.weight != null
                ? userData.weight!.toStringAsFixed(0)
                : '';
            _selectedGender = userData.gender;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    if (!RegExp(r'^[0-9+\s\-()]+$').hasMatch(value)) {
      return 'Invalid phone number format';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }
    final age = int.tryParse(value.trim());
    if (age == null) {
      return 'Enter a valid age';
    }
    if (age < 13 || age > 100) {
      return 'Age must be between 13 and 100';
    }
    return null;
  }

  String? _validateHeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }
    final height = double.tryParse(value.trim());
    if (height == null) {
      return 'Enter a valid height';
    }
    if (height < 100 || height > 220) {
      return 'Height must be 100-220 cm';
    }
    return null;
  }

  String? _validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }
    final weight = double.tryParse(value.trim());
    if (weight == null) {
      return 'Enter a valid weight';
    }
    if (weight < 30 || weight > 200) {
      return 'Weight must be 30-200 kg';
    }
    return null;
  }

  // ========== PHOTO UPLOAD FUNCTIONALITY ==========

  Future<void> _pickAndUploadPhoto() async {
    if (_currentUser == null) return;

    // Show bottom sheet to choose Camera or Gallery
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_camera,
                  color: AppColors.purple,
                ),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.purple,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (_currentUser?.photoUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _removePhoto();
                  },
                ),
            ],
          ),
        ),
      ),
    );

    // If user canceled or chose remove
    if (source == null) return;

    try {
      // Pick image
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploadingPhoto = true;
      });

      // Upload to Cloudinary via backend
      final File imageFile = File(image.path);
      final String userId = _currentUser!.uid;

      // Upload to Cloudinary
      final String downloadUrl = await CloudinaryService.uploadProfilePhoto(
        imageFile,
      );

      // Update Firestore
      await FirestoreService.updateUser(userId, {'photoUrl': downloadUrl});

      // Update Firebase Auth profile photo
      await FirebaseAuth.instance.currentUser?.updatePhotoURL(downloadUrl);

      // Reload user data to reflect changes
      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  Future<void> _removePhoto() async {
    if (_currentUser == null) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final String userId = _currentUser!.uid;

      // Update Firestore (remove photoUrl)
      await FirestoreService.updateUser(userId, {'photoUrl': null});

      // Update Firebase Auth profile photo
      await FirebaseAuth.instance.currentUser?.updatePhotoURL(null);

      // Note: Cloudinary images are not deleted to preserve history
      // You can implement Cloudinary deletion via backend if needed

      // Reload user data
      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo removed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  // ================================================

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User data not loaded'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Prepare update data
      final updateData = <String, dynamic>{};

      // Check if name changed
      if (_nameController.text.trim() != _currentUser!.name) {
        updateData['name'] = _nameController.text.trim();

        // Also update Firebase Auth display name
        await FirebaseAuth.instance.currentUser?.updateDisplayName(
          _nameController.text.trim(),
        );
      }

      // Check if phone changed
      if (_phoneController.text.trim() != (_currentUser!.phone ?? '')) {
        updateData['phone'] = _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim();
      }

      // Check if age changed
      final ageText = _ageController.text.trim();
      final newAge = ageText.isEmpty ? null : int.tryParse(ageText);
      if (newAge != _currentUser!.age) {
        updateData['age'] = newAge;
      }

      // Check if gender changed
      if (_selectedGender != _currentUser!.gender) {
        updateData['gender'] = _selectedGender;
      }

      // Check if height changed
      final heightText = _heightController.text.trim();
      final newHeight = heightText.isEmpty ? null : double.tryParse(heightText);
      if (newHeight != _currentUser!.height) {
        updateData['height'] = newHeight;
      }

      // Check if weight changed
      final weightText = _weightController.text.trim();
      final newWeight = weightText.isEmpty ? null : double.tryParse(weightText);
      if (newWeight != _currentUser!.weight) {
        updateData['weight'] = newWeight;
      }

      // Only update if there are changes
      if (updateData.isNotEmpty) {
        await FirestoreService.updateUser(_currentUser!.uid, updateData);

        // Reload user data
        await _loadUserData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No changes to save'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving changes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // -------- AVATAR --------
                      Center(
                        child: Stack(
                          children: [
                            // Show loading indicator while uploading
                            if (_isUploadingPhoto)
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: AppColors.purple.withOpacity(
                                  0.3,
                                ),
                                child: const CircularProgressIndicator(
                                  color: AppColors.purple,
                                ),
                              )
                            else
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: AppColors.purple,
                                backgroundImage: _currentUser?.photoUrl != null
                                    ? NetworkImage(_currentUser!.photoUrl!)
                                    : null,
                                child: _currentUser?.photoUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 48,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _isUploadingPhoto
                                    ? null
                                    : _pickAndUploadPhoto,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: _isUploadingPhoto
                                        ? Colors.grey
                                        : AppColors.purple,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // -------- EDITABLE FIELDS --------
                      _editableField(
                        label: 'Name',
                        controller: _nameController,
                        validator: _validateName,
                      ),

                      _readOnlyField(
                        label: 'Email',
                        value: _currentUser?.email ?? '',
                      ),

                      _editableField(
                        label: 'Phone',
                        controller: _phoneController,
                        validator: _validatePhone,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9+\s\-()]'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // -------- PERSONAL DETAILS SECTION --------
                      const Divider(height: 1),
                      const SizedBox(height: 20),
                      const Text(
                        'Personal Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Helps personalize your experience. Used for future size recommendations.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _genderField(),

                      _editableField(
                        label: 'Age',
                        controller: _ageController,
                        validator: _validateAge,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _editableField(
                              label: 'Height (cm)',
                              controller: _heightController,
                              validator: _validateHeight,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _editableField(
                              label: 'Weight (kg)',
                              controller: _weightController,
                              validator: _validateWeight,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // -------- SAVE BUTTON --------
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Editable field widget
  Widget _editableField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Gender dropdown field
  Widget _genderField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gender',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            isExpanded: true,
            hint: const Text('Select gender'),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'Male', child: Text('Male')),
              DropdownMenuItem(value: 'Female', child: Text('Female')),
              DropdownMenuItem(
                value: 'Prefer not to say',
                child: Text('Prefer not to say'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // Read-only field widget (for email)
  Widget _readOnlyField({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                ),
                const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
