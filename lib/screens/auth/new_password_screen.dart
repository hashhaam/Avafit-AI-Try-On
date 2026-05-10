import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  bool _isNewPasswordHidden = true;
  bool _isRepeatPasswordHidden = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Decorative gradient shape
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // Avatar
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 48,
                      color: AppColors.purple,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Setup New Password',
                    style: AppTextStyles.heading.copyWith(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Subtitle
                  const Text(
                    'Please, setup a new password\nfor your account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // New password
                  _passwordField(
                    hint: 'New Password',
                    isHidden: _isNewPasswordHidden,
                    onToggle: () {
                      setState(() {
                        _isNewPasswordHidden = !_isNewPasswordHidden;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Repeat password
                  _passwordField(
                    hint: 'Repeat Password',
                    isHidden: _isRepeatPasswordHidden,
                    onToggle: () {
                      setState(() {
                        _isRepeatPasswordHidden = !_isRepeatPasswordHidden;
                      });
                    },
                  ),

                  const Spacer(),

                  // Save button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        // UI-only: go back to login
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: Text(
                        'Save',
                        style: AppTextStyles.buttonText,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Cancel
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField({
    required String hint,
    required bool isHidden,
    required VoidCallback onToggle,
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              obscureText: isHidden,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              isHidden
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
