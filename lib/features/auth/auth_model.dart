import 'package:equatable/equatable.dart';

/// Foydalanuvchi ma'lumotlari modeli.
///
/// Bu model Google/Apple orqali kirishdan keyin to'plangan
/// foydalanuvchi ma'lumotlarini (ism, familiya, yosh, email, uid)
/// ifodalaydi.
class UserModel extends Equatable {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final int? age;
  final String? photoUrl;
  final String provider; // 'google' | 'apple' | 'email'
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.age,
    this.photoUrl,
    required this.provider,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Foydalanuvchi to'liq ismini qaytaradi.
  String get fullName => '$firstName $lastName'.trim();

  /// Foydalanuvchi ismini birinchi harfi (profil ikonasi uchun).
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    return (first + last).toUpperCase();
  }

  /// Foydalanuvchi ma'lumotlarini JSON formatiga o'tkazadi.
  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'age': age,
        'photoUrl': photoUrl,
        'provider': provider,
        'createdAt': createdAt.toIso8601String(),
      };

  /// JSON dan foydalanuvchi modelini yaratadi.
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: json['uid'] as String,
        email: json['email'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        age: json['age'] as int?,
        photoUrl: json['photoUrl'] as String?,
        provider: json['provider'] as String,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : null,
      );

  /// Modeldan nusxa olib, berilgan maydonlarni yangilaydi.
  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    int? age,
    String? photoUrl,
    String? provider,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [uid, email, firstName, lastName, age, photoUrl, provider, createdAt];
}
