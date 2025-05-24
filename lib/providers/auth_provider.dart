import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final _authService = AuthService();
  User? _user;
  bool _isLoading = false;

  AuthProvider() {
    // Initialize user from current state
    _user = _authService.currentUser;
    
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isAuth => _user != null;
  bool get isLoading => _isLoading;

  // Sign in with email and password
  Future<void> signIn({required String email, required String password}) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Register with email and password
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String shippingAddress = '',
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _authService.registerWithEmailAndPassword(
        name: name,
        email: email,
        password: password,
        shippingAddress: shippingAddress,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();
      await _authService.signInWithGoogle();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();
      await _authService.signOut();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _authService.resetPassword(email);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 