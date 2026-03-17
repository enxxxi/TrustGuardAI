// lib/models/auth_state.dart
import 'package:flutter/material.dart';

enum AuthStep { login, signup, setup, done }

class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String city;
  final String country;
  final String walletType;
  final String occupation;
  final String avatarEmoji;

  const UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.country,
    required this.walletType,
    required this.occupation,
    required this.avatarEmoji,
  });

  UserProfile copyWith({
    String? name, String? email, String? phone,
    String? city, String? country, String? walletType,
    String? occupation, String? avatarEmoji,
  }) => UserProfile(
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    city: city ?? this.city,
    country: country ?? this.country,
    walletType: walletType ?? this.walletType,
    occupation: occupation ?? this.occupation,
    avatarEmoji: avatarEmoji ?? this.avatarEmoji,
  );
}

class AuthState extends ChangeNotifier {
  AuthStep _step = AuthStep.login;
  AuthStep get step => _step;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  bool _loading = false;
  bool get loading => _loading;

  UserProfile _profile = const UserProfile(
    name: 'Aisha Binti Razak',
    email: 'aisha@example.com',
    phone: '+60 12-345 6789',
    city: 'Johor Bahru',
    country: 'Malaysia',
    walletType: 'GrabPay',
    occupation: 'Gig Worker',
    avatarEmoji: '👩',
  );
  UserProfile get profile => _profile;

  void goToSignup() { _step = AuthStep.signup; notifyListeners(); }
  void goToLogin()  { _step = AuthStep.login;  notifyListeners(); }
  void goToSetup()  { _step = AuthStep.setup;  notifyListeners(); }

  Future<void> login(String email, String password) async {
    _loading = true; notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1200));
    _isLoggedIn = true;
    _step = AuthStep.done;
    _loading = false;
    notifyListeners();
  }

  Future<void> signup(String name, String email, String password) async {
    _loading = true; notifyListeners();
    await Future.delayed(const Duration(milliseconds: 1200));
    _profile = _profile.copyWith(name: name, email: email);
    _step = AuthStep.setup;
    _loading = false;
    notifyListeners();
  }

  Future<void> completeSetup(UserProfile updated) async {
    _loading = true; notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));
    _profile = updated;
    _isLoggedIn = true;
    _step = AuthStep.done;
    _loading = false;
    notifyListeners();
  }

  void updateProfile(UserProfile updated) {
    _profile = updated;
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _step = AuthStep.login;
    notifyListeners();
  }
}
