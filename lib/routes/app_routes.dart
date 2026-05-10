import 'package:flutter/material.dart';

// 🔐 Auth
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/password_recovery_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/new_password_screen.dart';

// 🚀 Splash / Onboarding
import '../screens/splash/app_splash_screen.dart';
import '../screens/splash/splash_screen.dart';

// 🧭 Post-login cards
import '../screens/post_login/hello_card_screen.dart';
import '../screens/post_login/ready_card_screen.dart';

// 🏠 Main App
import '../screens/main_scaffold.dart';

// ⚙️ Settings
import '../screens/settings/settings_screen.dart';
import '../screens/profile/settings_profile_screen.dart';

class AppRoutes {
  // 🔥 ROUTE NAMES
  static const appSplash = '/';                 // Animated splash
  static const onboarding = '/onboarding';     // Signup / Login screen

  static const login = '/login';
  static const signup = '/signup';

  static const passwordRecovery = '/password-recovery';
  static const otp = '/otp';
  static const newPassword = '/new-password';

  static const helloCard = '/hello-card';
  static const readyCard = '/ready-card';

  static const main = '/main';
  static const settings = '/settings';
  static const settingsProfile = '/settings-profile';

  // 🔥 ROUTES MAP
  static Map<String, WidgetBuilder> routes = {
    appSplash: (_) => const AppSplashScreen(),
    onboarding: (_) => const SplashScreen(),

    login: (_) => const LoginScreen(),
    signup: (_) => const SignupScreen(),

    passwordRecovery: (_) => const PasswordRecoveryScreen(),
    otp: (_) => const OtpScreen(),
    newPassword: (_) => const NewPasswordScreen(),

    helloCard: (_) => const HelloCardScreen(),
    readyCard: (_) => const ReadyCardScreen(),

    main: (_) => const MainScaffold(),
    settings: (_) => const SettingsScreen(),
    settingsProfile: (_) => const SettingsProfileScreen(),
  };
}



// import 'package:flutter/material.dart';

// // Auth
// import '../screens/auth/login_screen.dart';
// import '../screens/auth/signup_screen.dart';
// import '../screens/auth/password_recovery_screen.dart';

// // Splash
// import '../screens/splash/app_splash_screen.dart'; // NEW animated splash
// import '../screens/splash/splash_screen.dart';     // OLD onboarding

// // Main
// import '../screens/main_scaffold.dart';

// // Settings
// import '../screens/settings/settings_screen.dart';
// import '../screens/profile/settings_profile_screen.dart';

// class AppRoutes {
//   // 🔹 ROUTE NAMES
//   static const appSplash = '/';              // Animated splash (ENTRY)
//   static const onboarding = '/onboarding';  // Old splash (login/signup)
//   static const login = '/login';
//   static const signup = '/signup';
//   static const passwordRecovery = '/password-recovery';

//   static const main = '/main';
//   static const settings = '/settings';
//   static const settingsProfile = '/settings-profile';

//   // 🔹 ROUTES MAP
//   static final Map<String, WidgetBuilder> routes = {
//     appSplash: (_) => const AppSplashScreen(),
//     onboarding: (_) => const SplashScreen(),

//     login: (_) => const LoginScreen(),
//     signup: (_) => const SignupScreen(),
//     passwordRecovery: (_) => const PasswordRecoveryScreen(),

//     main: (_) => const MainScaffold(),
//     settings: (_) => const SettingsScreen(),
//     settingsProfile: (_) => const SettingsProfileScreen(),
//   };
// }
