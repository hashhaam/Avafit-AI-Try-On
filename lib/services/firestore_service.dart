import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  // -------------------- CREATE USER --------------------
  /// Creates a new user document in Firestore
  static Future<void> createUser(UserModel user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.uid)
          .set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  // -------------------- GET USER --------------------
  /// Gets user data from Firestore by UID
  static Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();

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
      final doc = await _firestore.collection(_usersCollection).doc(uid).get();
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

  // ==================== WISHLIST ====================

  /// Reference to a user's wishlist collection
  static CollectionReference<Map<String, dynamic>> _wishlistRef(String uid) {
    return _firestore
        .collection(_usersCollection)
        .doc(uid)
        .collection('wishlist');
  }

  /// Add a garment to the user's wishlist
  static Future<void> addToWishlist(
    String uid,
    Map<String, dynamic> garment,
  ) async {
    try {
      final garmentId = garment['id']?.toString();
      if (garmentId == null || garmentId.isEmpty) {
        throw Exception('Garment has no id');
      }
      final data = Map<String, dynamic>.from(garment);
      data['addedAt'] = DateTime.now().toIso8601String();
      await _wishlistRef(uid).doc(garmentId).set(data);
    } catch (e) {
      throw Exception('Failed to add to wishlist: $e');
    }
  }

  /// Remove a garment from the user's wishlist
  static Future<void> removeFromWishlist(String uid, String garmentId) async {
    try {
      await _wishlistRef(uid).doc(garmentId).delete();
    } catch (e) {
      throw Exception('Failed to remove from wishlist: $e');
    }
  }

  /// Check if a garment is in the user's wishlist
  static Future<bool> isInWishlist(String uid, String garmentId) async {
    try {
      final doc = await _wishlistRef(uid).doc(garmentId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get all wishlist garments for a user (most recent first)
  static Future<List<Map<String, dynamic>>> getWishlist(String uid) async {
    try {
      final snapshot = await _wishlistRef(uid).get();
      final items = snapshot.docs.map((d) => d.data()).toList();
      items.sort((a, b) {
        final aDate = a['addedAt']?.toString() ?? '';
        final bDate = b['addedAt']?.toString() ?? '';
        return bDate.compareTo(aDate);
      });
      return items;
    } catch (e) {
      throw Exception('Failed to load wishlist: $e');
    }
  }
}
