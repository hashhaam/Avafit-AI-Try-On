import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final String? photoUrl;
  final int? age;
  final String? gender;
  final double? height; // in cm
  final double? weight; // in kg
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    this.photoUrl,
    this.age,
    this.gender,
    this.height,
    this.weight,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert UserModel to Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'photoUrl': photoUrl,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'],
      photoUrl: map['photoUrl'],
      age: map['age'] != null ? (map['age'] as num).toInt() : null,
      gender: map['gender'],
      height: map['height'] != null ? (map['height'] as num).toDouble() : null,
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  // Create UserModel from Firestore DocumentSnapshot
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data);
  }

  // Copy with method (for updates)
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? phone,
    String? photoUrl,
    int? age,
    String? gender,
    double? height,
    double? weight,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
