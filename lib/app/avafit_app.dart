import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../utils/colors.dart';

class AvaFitApp extends StatelessWidget {
  const AvaFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AvaFit',
      debugShowCheckedModeBanner: false,

      // 🔥 App starts from animated splash
      initialRoute: AppRoutes.appSplash,
      routes: AppRoutes.routes,

      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'SF Pro Display',
        useMaterial3: true,
      ),
    );
  }
}


