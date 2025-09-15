import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/theme_provider.dart';
import 'theme/app_themes.dart';
import 'services/feature_flag_service.dart';
import 'services/error_tracking_service.dart';
import 'authmethod.dart';
import 'revenuecat_manager.dart';

import 'screens/main_screen.dart';
import 'environment.dart';
import 'subscription_required.dart';
import 'apple_iap_service.dart';
import 'google_iap_service.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FeatureFlags.initialize();

    // Initialize Supabase
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseKey,
    );

    // Check for existing session and get user ID for RevenueCat
    final currentSession = Supabase.instance.client.auth.currentSession;
    final initialUserId = currentSession?.user?.id;

    // Initialize RevenueCat with initial user ID if available
    await RevenueCatManager.initialize(initialUserId: initialUserId);
    
    // If we have a user, do a nuclear reset to clear any anonymous users
    if (initialUserId != null) {
      print('Performing nuclear reset to clear anonymous users');
      await RevenueCatManager.clearAllData();
      await RevenueCatManager.setRevenueCatUser(initialUserId);
    }

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Initialize custom error tracking system
    print('Initializing custom error tracking system');
    runApp(MyApp());
  } catch (e, stack) {
    // Capture startup errors in custom error tracking
    try {
      await ErrorTrackingService.captureGeneralError(
        e,
        stack,
        context: 'app_startup',
      );
    } catch (trackingError) {
      debugPrint('Failed to track startup error: $trackingError');
    }
    
    debugPrint('Startup error: $e');
    debugPrint('Stack: $stack');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Startup error:\n\nError: $e\n\nStack: $stack',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthState()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'RideWealth Assistant',
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeProvider.themeMode,
            home: AuthWrapper(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  AuthWrapperState createState() => AuthWrapperState();
}

class AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthState>(
      builder: (context, authState, child) {
        if (authState.user != null) {
          // Check subscription status before allowing access
          return FutureBuilder<bool>(
            future: _checkSubscriptionStatus(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              final hasSubscription = snapshot.data ?? false;
              
              if (hasSubscription) {
                return MainScreen();
              } else {
                // Force subscription screen
                return SubscriptionRequiredScreen(
                  iapService: Platform.isIOS ? AppleIAPService() : GoogleIAPService(),
                );
              }
            },
          );
        } else {
          return AuthScreen();
        }
      },
    );
  }

  Future<bool> _checkSubscriptionStatus() async {
    try {
      // Check if user has active subscription or trial
      final isSubscribed = await RevenueCatManager.isSubscribed();
      final trialStatus = await RevenueCatManager.getTrialStatus();
      
      // Allow access if subscribed OR in trial
      return isSubscribed || (trialStatus['isInTrial'] == true);
    } catch (e) {
      print('Error checking subscription status: $e');
      // Default to requiring subscription on error
      return false;
    }
  }
}

class AuthScreen extends StatefulWidget {
  @override
  AuthScreenState createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign In')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildOAuthButton(
                'Sign in with Google',
                'https://www.google.com/favicon.ico',
                () async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  try {
                    final result = await signInWithGoogle();
                    if (!result) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                            content: Text(
                                'Failed to sign in with Google. Please try again.')),
                      );
                    }
                  } catch (e, stack) {
                    await ErrorTrackingService.captureUIError(
                      e,
                      stack,
                      screen: 'auth_screen',
                      action: 'google_sign_in',
                    );
                    print('Google sign in UI error: $e');
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('An error occurred. Please try again.')),
                    );
                  }
                },
              ),
              SizedBox(height: 16),
              _buildOAuthButton(
                'Sign in with Apple',
                'https://www.apple.com/favicon.ico',
                () async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  try {
                    final result = await signInWithApple();
                    if (!result) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                            content: Text(
                                'Failed to sign in with Apple. Please try again.')),
                      );
                    }
                  } catch (e, stack) {
                    await ErrorTrackingService.captureUIError(
                      e,
                      stack,
                      screen: 'auth_screen',
                      action: 'apple_sign_in',
                    );
                    print('Apple sign in UI error: $e');
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('An error occurred. Please try again.')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOAuthButton(String text, String logoUrl, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.network(
                  logoUrl,
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.account_circle, size: 24, color: Colors.grey);
                  },
                ),
                SizedBox(width: 12),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthState extends ChangeNotifier {
  User? _user;

  User? get user => _user;

  AuthState() {
    _initializeAuth();
  }

  void _initializeAuth() {
    print('Initializing auth state listener...');
    
    // Check if there's already an existing session and set RevenueCat user immediately
    final currentSession = Supabase.instance.client.auth.currentSession;
    if (currentSession?.user != null) {
      print('Found existing session, setting RevenueCat user immediately');
      RevenueCatManager.setRevenueCatUser(currentSession!.user!.id);
    }
    
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      print('=== Auth State Change ===');
      print('Event: ${data.event}');
      print('Session: ${data.session != null ? 'exists' : 'null'}');
      print('User: ${data.session?.user?.id ?? 'null'}');
      
      try {
        _user = data.session?.user;
        if (_user != null) {
          print('User authenticated: ${_user!.id}');
          await createSupabaseUserDocument(_user!);
          // Sync user with RevenueCat
          await RevenueCatManager.setRevenueCatUser(_user!.id);
          
          // Debug: Get current RevenueCat user ID
          final revenueCatUserId = await RevenueCatManager.getCurrentRevenueCatUserId();
          print('Supabase user ID: ${_user!.id}');
          print('RevenueCat user ID: $revenueCatUserId');
        } else {
          print('No user in session');
        }
        notifyListeners();
      } catch (e, stack) {
        await ErrorTrackingService.captureGeneralError(
          e,
          stack,
          context: 'auth_state_change',
        );
        print('Auth state change error: $e');
      }
      print('=== End Auth State Change ===');
    });
  }

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e, stack) {
      await ErrorTrackingService.captureAuthError(
        e,
        stack,
        authMethod: 'signout',
      );
      print('Sign out error in AuthState: $e');
      rethrow;
    }
  }
}
