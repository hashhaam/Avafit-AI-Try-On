import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  // -------------------- CREATE USER --------------------
  /// Creates a new user document in Firestore
  static Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection(_usersCollection).doc(user.uid).set(
            user.toMap(),
          );
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  // -------------------- GET USER --------------------
  /// Gets user data from Firestore by UID
  static Future<UserModel?> getUser(String uid) async {
    try {
      final doc =
          await _firestore.collection(_usersCollection).doc(uid).get();

      if (doc.exists) {
        return UserModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // -------------------- UPDATE USER --------------------
  /// Updates user data in Firestore
  static Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      // Add updatedAt timestamp
      data['updatedAt'] = DateTime.now().toIso8601String();

      await _firestore.collection(_usersCollection).doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // -------------------- DELETE USER --------------------
  /// Deletes user document from Firestore
  static Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection(_usersCollection).doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  // -------------------- CHECK IF USER EXISTS --------------------
  /// Checks if user document exists in Firestore
  static Future<bool> userExists(String uid) async {
    try {
      final doc =
          await _firestore.collection(_usersCollection).doc(uid).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check user existence: $e');
    }
  }

  // -------------------- UPDATE USER NAME --------------------
  /// Updates only the user's name
  static Future<void> updateUserName(String uid, String name) async {
    await updateUser(uid, {'name': name});
  }

  // -------------------- UPDATE USER PHONE --------------------
  /// Updates only the user's phone number
  static Future<void> updateUserPhone(String uid, String phone) async {
    await updateUser(uid, {'phone': phone});
  }

  // -------------------- UPDATE USER PHOTO --------------------
  /// Updates only the user's photo URL
  static Future<void> updateUserPhoto(String uid, String photoUrl) async {
    await updateUser(uid, {'photoUrl': photoUrl});
  }
}