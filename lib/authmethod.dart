import 'package:supabase_flutter/supabase_flutter.dart';
import 'revenuecat_manager.dart';

final supabase = Supabase.instance.client;

Future<void> createSupabaseUserDocument(User user) async {
  try {
    // Try to get existing user
    await supabase.from('users').select().eq('id', user.id).single();

    // User exists, no need to update anything
  } catch (e) {
    // User doesn't exist, create new user
    try {
      await supabase.from('users').insert({
        'id': user.id,
        'email': user.email,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (insertError, insertStack) {
      print('Error creating user document: $insertError');
      rethrow;
    }
  }
}

Future<AuthResponse?> signInWithEmailAndPassword(
    String email, String password) async {
  try {
    final response = await supabase.auth
        .signInWithPassword(email: email, password: password);
    if (response.user != null) {
      await createSupabaseUserDocument(response.user!);
      // Log user into RevenueCat
      await RevenueCatManager.setRevenueCatUser(response.user!.id);
    }
    return response;
  } catch (e, stack) {
    print('Email/password sign in error: $e');
    rethrow;
  }
}

Future<AuthResponse?> signUpWithEmailAndPassword(
    String email, String password) async {
  try {
    final response =
        await supabase.auth.signUp(email: email, password: password);
    if (response.user != null) {
      await createSupabaseUserDocument(response.user!);
      // Log user into RevenueCat
      await RevenueCatManager.setRevenueCatUser(response.user!.id);
    }
    return response;
  } catch (e, stack) {
    print('Email/password sign up error: $e');
    rethrow;
  }
}

Future<void> signOut() async {
  try {
    await supabase.auth.signOut();
  } catch (e, stack) {
    print('Sign out error: $e');
    rethrow;
  }
}
