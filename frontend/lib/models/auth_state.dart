// lib/models/auth_state.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  AuthState() {
    _authSub = _auth.authStateChanges().listen(_handleAuthChanged);
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final StreamSubscription<User?> _authSub;

  AuthStep _step = AuthStep.login;
  AuthStep get step => _step;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  bool _loading = false;
  bool get loading => _loading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

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
    _setLoading(true);
    _errorMessage = null;

    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e);
    } catch (_) {
      _errorMessage = 'Unable to sign in right now. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signup(String name, String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await credential.user?.updateDisplayName(name.trim());
      _profile = _profile.copyWith(name: name.trim(), email: email.trim());
      _step = AuthStep.setup;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e);
    } catch (_) {
      _errorMessage = 'Unable to create your account right now.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> completeSetup(UserProfile updated) async {
    _setLoading(true);
    _profile = updated;
    _isLoggedIn = true;
    _step = AuthStep.done;
    _setLoading(false);
  }

  void updateProfile(UserProfile updated) {
    _profile = updated;
    notifyListeners();
  }

  Future<void> logout() async {
    _errorMessage = null;
    _isLoggedIn = false;
    _step = AuthStep.login;
    notifyListeners();
    await _auth.signOut();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _handleAuthChanged(User? user) {
    _isLoggedIn = user != null;

    if (user == null) {
      _step = AuthStep.login;
      notifyListeners();
      return;
    }

    _profile = _profile.copyWith(
      name: (user.displayName?.trim().isNotEmpty ?? false)
          ? user.displayName!.trim()
          : _profile.name,
      email: user.email ?? _profile.email,
    );

    if (_step == AuthStep.setup) {
      notifyListeners();
      return;
    }

    _step = AuthStep.done;
    notifyListeners();
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'That email is already registered.';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}
