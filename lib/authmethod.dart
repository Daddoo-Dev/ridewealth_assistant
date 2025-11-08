import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
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
    
    // User exists, update last login
    await supabase
        .from('users')
        .update({
          'last_login': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id);
  } catch (e) {
    // User doesn't exist, create new user
    try {
      await supabase.from('users').insert({
        'id': user.id,
        'email': user.email,
        'created_at': DateTime.now().toIso8601String(),
        'last_login': DateTime.now().toIso8601String(),
      });
    } catch (insertError, insertStack) {
      // Capture database errors in Sentry
      await ErrorTrackingService.captureDatabaseError(
        insertError,
        insertStack,
        operation: 'create_user',
        table: 'users',
        userId: user.id,
      );
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

Future<bool> signInWithGoogle() async {
  try {
    if (kIsWeb) {
      // Use OAuth for web
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
      );
      print('DEBUG: Web Google OAuth completed successfully');
      return true;
    } else {
      // Use native Google Sign-In for mobile
      const webClientId = '171871758415-72482kugocj99k7lt2s8q64s6hp3kmr7.apps.googleusercontent.com';
      
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );
      
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print('Google sign-in was cancelled');
        return false;
      }
      
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw 'No Access Token found.';
      }
      if (idToken == null) {
        throw 'No ID Token found.';
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
      print('DEBUG: Native Google signInWithIdToken completed successfully');
      return true;
    }
  } catch (e, stack) {
    await ErrorTrackingService.captureAuthError(
      e,
      stack,
      authMethod: 'google',
      extra: {'platform': kIsWeb ? 'web' : 'mobile'},
    );
    print('Error signing in with Google: $e');
    return false;
  }
}

Future<bool> signInWithApple() async {
  try {
    // Use Supabase OAuth for Flutter with explicit redirect URI for Android
    String redirectUrl = kIsWeb ? '${Uri.base.origin}/' : 'com.ridewealthassistant.app://';
    
    print('DEBUG: Using Apple redirectUrl: $redirectUrl');
    
    final result = await supabase.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: redirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    
    print('DEBUG: Apple OAuth result: $result');
    return true;
  } catch (e, stack) {
    await ErrorTrackingService.captureAuthError(
      e,
      stack,
      authMethod: 'apple',
      extra: {'platform': kIsWeb ? 'web' : 'mobile'},
    );
    print('Apple Sign In Error: $e');
    return false;
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