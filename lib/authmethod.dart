import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

final supabase = Supabase.instance.client;

Future<void> createSupabaseUserDocument(User user) async {
  try {
    // Try to get existing user
    await supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .single();
    
    // User exists, update last login
    await supabase
        .from('users')
        .update({
          'last_login': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
  } catch (e) {
    // User doesn't exist, create new user
    await supabase.from('users').insert({
      'id': user.id,
      'email': user.email,
      'created_at': DateTime.now().toIso8601String(),
      'last_login': DateTime.now().toIso8601String(),
    });
  }
}

Future<AuthResponse?> signInWithEmailAndPassword(String email, String password) async {
  final response = await supabase.auth.signInWithPassword(email: email, password: password);
  if (response.user != null) {
    await createSupabaseUserDocument(response.user!);
  }
  return response;
}

Future<AuthResponse?> signUpWithEmailAndPassword(String email, String password) async {
  final response = await supabase.auth.signUp(email: email, password: password);
  if (response.user != null) {
    await createSupabaseUserDocument(response.user!);
  }
  return response;
}

Future<bool> signInWithGoogle() async {
  try {
    String? redirectUrl;
    if (kIsWeb) {
      redirectUrl = Uri.base.origin + '/';
    } else {
      redirectUrl = 'com.ridewealthassistant.app://login-callback';
    }
    print('DEBUG: Using redirectUrl: ' + (redirectUrl ?? 'null'));
    
    await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
    );
    
    print('DEBUG: OAuth signInWithOAuth completed successfully');
    return true;
  } catch (e) {
    print('Error signing in with Google: $e');
    return false;
  }
}

Future<bool> signInWithApple() async {
  try {
    await supabase.auth.signInWithOAuth(OAuthProvider.apple);
    return true;
  } catch (e) {
    print('Apple Sign In Error: $e');
    return false;
  }
}

Future<void> signOut() async {
  await supabase.auth.signOut();
}