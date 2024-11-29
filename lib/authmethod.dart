import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

String generateNonce([int length = 32]) {
  const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)])
      .join();
}

String sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

Future<void> createUserDocument(User user) async {
  final userDoc = _firestore.collection('users').doc(user.uid);
  final docSnapshot = await userDoc.get();

  if (!docSnapshot.exists) {
    await userDoc.set({
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    });
  } else {
    await userDoc.update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }
}

Future<UserCredential?> signInWithGoogle() async {
  try {
    FirebaseCrashlytics.instance.log('Starting Google Sign In process');

    GoogleAuthProvider googleProvider = GoogleAuthProvider();

    googleProvider.addScope('email');
    googleProvider.setCustomParameters({'login_hint': 'user@example.com'});

    UserCredential userCredential;
    if (kIsWeb) {
      userCredential = await _auth.signInWithPopup(googleProvider);
    } else {
      final googleUser = await _auth.signInWithProvider(googleProvider);
      userCredential = googleUser;
    }

    if (userCredential.user != null) {
      await createUserDocument(userCredential.user!);
    }

    FirebaseCrashlytics.instance
        .log('Google Sign In successful: ${userCredential.user?.uid}');

    return userCredential;
  } catch (e, stackTrace) {
    FirebaseCrashlytics.instance
        .log('Detailed error signing in with Google: $e');

    if (e is FirebaseAuthException) {
      FirebaseCrashlytics.instance
          .log('Error code: ${e.code}, message: ${e.message}');
    }

    await FirebaseCrashlytics.instance.recordError(e, stackTrace);
    await FirebaseCrashlytics.instance.sendUnsentReports();

    return null;
  }
}

Future<UserCredential?> signInWithApple() async {
  try {
    final rawNonce = generateNonce();
    final nonce = sha256ofString(rawNonce);

    final appleProvider = OAuthProvider('apple.com')
      ..addScope('email')
      ..addScope('name')
      ..setCustomParameters({
        'nonce': nonce,
      });

    final userCredential = await _auth.signInWithProvider(appleProvider);

    if (userCredential.user != null) {
      await createUserDocument(userCredential.user!);
    }

    return userCredential;
  } catch (e, stackTrace) {
    print('Apple Sign In Error: $e');
    await FirebaseCrashlytics.instance.recordError(e, stackTrace);
    return null;
  }
}

Future<UserCredential?> signInWithEmailAndPassword(
    String email, String password) async {
  try {
    final userCredential = await _auth.signInWithEmailAndPassword(
        email: email, password: password);

    if (userCredential.user != null) {
      await createUserDocument(userCredential.user!);
    }

    return userCredential;
  } catch (e) {
    print('Error signing in with email and password: $e');
    if (!kIsWeb) {
      await FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    }
    return null;
  }
}