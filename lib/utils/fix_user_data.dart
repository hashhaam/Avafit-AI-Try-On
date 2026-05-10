/// Utility to fix missing Firestore user documents
/// Run this once if user data is not loading

import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class FixUserData {
  /// Creates Firestore document for currently logged-in user if missing
  static Future<bool> fixCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print('❌ No user is currently logged in');
        return false;
      }

      // Check if user document exists
      final exists = await FirestoreService.userExists(user.uid);

      if (exists) {
        print('✅ User document already exists');
        return true;
      }

      // Create missing user document
      print('📝 Creating Firestore document for user: ${user.email}');

      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? 'User',
        phone: user.phoneNumber,
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
      );

      await FirestoreService.createUser(userModel);

      print('✅ User document created successfully!');
      return true;
    } catch (e) {
      print('❌ Error fixing user data: $e');
      return false;
    }
  }
}
