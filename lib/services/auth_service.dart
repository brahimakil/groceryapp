import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../consts/firebase_consts.dart';

class AuthService {
  // Use the existing Firebase Auth instance
  final FirebaseAuth _auth = authInstance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
    String shippingAddress = '',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Update display name
    await credential.user?.updateDisplayName(name);
    
    // Create user document in Firestore
    await _createUserDocument(
      credential.user!, 
      name,
      shippingAddress,
    );
    
    return credential;
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      UserCredential? userCredential;
      
      // For web
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.setCustomParameters({
          'prompt': 'select_account',
        });
        userCredential = await _auth.signInWithPopup(googleProvider);
      } 
      // For mobile
      else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }
      
      // Check if user document exists in Firestore
      if (userCredential != null && userCredential.user != null) {
        final user = userCredential.user!;
        
        // Check if the user's document exists in Firestore
        final docSnapshot = await _firestore.collection('users').doc(user.uid).get();
        
        // If document doesn't exist, create it (regardless of whether user is new)
        if (!docSnapshot.exists) {
          await _createUserDocument(
            user, 
            user.displayName ?? 'User',
          );
        }
      }
      
      return userCredential;
    } catch (error) {
      print('Error signing in with Google: $error');
      rethrow;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user, String name, [String shippingAddress = '']) async {
    await _firestore.collection('users').doc(user.uid).set({
      'id': user.uid,
      'name': name,
      'email': user.email,
      'shipping-address': shippingAddress,
      'userWish': [],
      'userCart': [],
      'createdAt': Timestamp.now(),
    });
  }

  // Sign out
  Future<void> signOut() async {
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
} 