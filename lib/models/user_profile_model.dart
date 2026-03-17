import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String name;
  final int age;
  final String gender;
  final List<String> healthConditions;
  final String emergencyContact;
  final DateTime createdAt;

  UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.healthConditions,
    this.emergencyContact = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get ageGroup {
    if (age <= 5) return 'Toddler';
    if (age <= 12) return 'Child';
    if (age <= 17) return 'Teen';
    if (age <= 45) return 'Adult';
    if (age <= 60) return 'Middle Aged';
    if (age <= 75) return 'Senior';
    return 'Elderly';
  }

  String get riskLevel {
    if (age <= 5 || age > 75) return 'Very High';
    if (age <= 12 || age > 60) return 'High';
    if (healthConditions.any((c) => ['asthma', 'copd', 'bronchitis', 'breathing', 'heart'].contains(c))) return 'High';
    if (healthConditions.any((c) => ['allergy', 'sinusitis', 'eye_irritation', 'skin'].contains(c))) return 'Moderate';
    if (healthConditions.isNotEmpty && !healthConditions.contains('none')) return 'Moderate';
    return 'Normal';
  }

  String get riskEmoji {
    switch (riskLevel) {
      case 'Very High': return '🔴';
      case 'High': return '🟠';
      case 'Moderate': return '🟡';
      default: return '🟢';
    }
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'gender': gender,
    'healthConditions': healthConditions,
    'emergencyContact': emergencyContact,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    name: json['name'] ?? '',
    age: json['age'] ?? 25,
    gender: json['gender'] ?? 'Other',
    healthConditions: List<String>.from(json['healthConditions'] ?? []),
    emergencyContact: json['emergencyContact'] ?? '',
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
  );

  static Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', json.encode(profile.toJson()));
  }

  static Future<UserProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user_profile');
    if (data == null) return null;
    return UserProfile.fromJson(json.decode(data));
  }

  static Future<void> delete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_profile');
  }

  static Future<bool> exists() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('user_profile');
  }
}