// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../../routes/app_routes.dart';

// class AppSplashScreen extends StatefulWidget {
//   const AppSplashScreen({super.key});

//   @override
//   State<AppSplashScreen> createState() => _AppSplashScreenState();
// }

// class _AppSplashScreenState extends State<AppSplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _navigate();
//   }

//   Future<void> _navigate() async {
//     await Future.delayed(const Duration(seconds: 2));

//     final user = FirebaseAuth.instance.currentUser;

//     if (!mounted) return;

//     if (user != null) {
//       // ✅ User already logged in
//       Navigator.pushReplacementNamed(context, AppRoutes.main);
//     } else {
//       // ❌ New / logged-out user
//       Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: Center(
//         child: CircularProgressIndicator(),
//       ),
//     );
//   }
// }

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../../routes/app_routes.dart';

// class AppSplashScreen extends StatefulWidget {
//   const AppSplashScreen({super.key});

//   @override
//   State<AppSplashScreen> createState() => _AppSplashScreenState();
// }

// class _AppSplashScreenState extends State<AppSplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     _decideNext();
//   }

//   Future<void> _decideNext() async {
//     await Future.delayed(const Duration(seconds: 2));

//     final user = FirebaseAuth.instance.currentUser;
//     if (!mounted) return;

//     if (user != null) {
//       // ✅ Logged in → Home
//       Navigator.pushReplacementNamed(context, AppRoutes.main);
//     } else {
//       // ❌ Logged out / New user → Onboarding
//       Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: Center(
//         child: CircularProgressIndicator(),
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../routes/app_routes.dart';

class AppSplashScreen extends StatefulWidget {
  const AppSplashScreen({super.key});

  @override
  State<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends State<AppSplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // Wait for splash animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Wait for Firebase Auth to initialize properly
    await Future.delayed(const Duration(milliseconds: 100));

    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user != null) {
      // ✅ User already logged in
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    } else {
      // ❌ New / logged-out user
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
