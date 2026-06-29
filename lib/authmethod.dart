import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final supabase = Supabase.instance.client;

Future<void> createSupabaseUserDocument(User user) async {
  try {
    await supabase.from('users').upsert({
      'id': user.id,
      'email': user.email,
      'created_at': DateTime.now().toIso8601String(),
    }, onConflict: 'id', ignoreDuplicates: true);
  } catch (e, stack) {
    debugPrint('Error creating user document: $e');
    Sentry.captureException(e, stackTrace: stack);
    rethrow;
  }
}

Future<AuthResponse?> signInWithEmailAndPassword(
    String email, String password) async {
  try {
    final response = await supabase.auth
        .signInWithPassword(email: email, password: password);
    return response;
  } catch (e, stack) {
    debugPrint('Email/password sign in error: $e');
    Sentry.captureException(e, stackTrace: stack);
    rethrow;
  }
}

Future<AuthResponse?> signUpWithEmailAndPassword(
    String email, String password) async {
  try {
    final response =
        await supabase.auth.signUp(email: email, password: password);
    return response;
  } catch (e, stack) {
    debugPrint('Email/password sign up error: $e');
    Sentry.captureException(e, stackTrace: stack);
    rethrow;
  }
}

Future<void> signOut() async {
  try {
    await supabase.auth.signOut();
  } catch (e, stack) {
    debugPrint('Sign out error: $e');
    Sentry.captureException(e, stackTrace: stack);
    rethrow;
  }
}
