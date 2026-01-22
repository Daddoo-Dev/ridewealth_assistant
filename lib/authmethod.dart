import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/error_tracking_service.dart';
import 'revenuecat_manager.dart';

final supabase = Supabase.instance.client;

Future<void> createSupabaseUserDocument(User user) async {
  try {
    // Try to get existing user
    await supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .single();
    
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
      // Capture database errors (but don't fail if error_tracking doesn't exist)
      try {
        await ErrorTrackingService.captureDatabaseError(
          insertError,
          insertStack,
          operation: 'create_user',
          table: 'users',
          userId: user.id,
        );
      } catch (_) {
        // Ignore error tracking failures
      }
      print('Error creating user document: $insertError');
      rethrow;
    }
  }
}

Future<AuthResponse?> signInWithEmailAndPassword(String email, String password) async {
  try {
    final response = await supabase.auth.signInWithPassword(email: email, password: password);
    if (response.user != null) {
      await createSupabaseUserDocument(response.user!);
      await ErrorTrackingService.setUserContext(response.user!.id, email: response.user!.email);
      // Log user into RevenueCat
      await RevenueCatManager.setRevenueCatUser(response.user!.id);
    }
    return response;
  } catch (e, stack) {
    await ErrorTrackingService.captureAuthError(
      e,
      stack,
      authMethod: 'email_password',
      extra: {'email': email},
    );
    print('Email/password sign in error: $e');
    return null;
  }
}

Future<AuthResponse?> signUpWithEmailAndPassword(String email, String password) async {
  try {
    final response = await supabase.auth.signUp(email: email, password: password);
    if (response.user != null) {
      await createSupabaseUserDocument(response.user!);
      await ErrorTrackingService.setUserContext(response.user!.id, email: response.user!.email);
      // Log user into RevenueCat
      await RevenueCatManager.setRevenueCatUser(response.user!.id);
    }
    return response;
  } catch (e, stack) {
    await ErrorTrackingService.captureAuthError(
      e,
      stack,
      authMethod: 'email_signup',
      extra: {'email': email},
    );
    print('Email/password sign up error: $e');
    return null;
  }
}

Future<void> signOut() async {
  try {
    await ErrorTrackingService.clearUserContext();
    await supabase.auth.signOut();
  } catch (e, stack) {
    await ErrorTrackingService.captureAuthError(
      e,
      stack,
      authMethod: 'signout',
    );
    print('Sign out error: $e');
    rethrow;
  }
}