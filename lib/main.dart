import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'theme/theme_provider.dart';
import 'theme/app_themes.dart';
import 'authmethod.dart';
import 'revenuecat_manager.dart';

import 'screens/main_screen.dart';
import 'screens/demo_screen.dart';
import 'screens/web_signin_animation.dart';
import 'environment.dart';
import 'subscription_required.dart';
import 'error_messages.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import 'widgets/store_download_badges.dart';

void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn =
          Environment.sentryDsn.isNotEmpty ? Environment.sentryDsn : null;
      // Only capture app-layer errors (Dart/Flutter), not native OS crashes (e.g. OOM, device kills)
      options.autoInitializeNativeSdk = false;
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();
      try {
        await Supabase.initialize(
          url: Environment.supabaseUrl,
          anonKey: Environment.supabaseKey,
          authOptions: const FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
          ),
        );

        final currentSession = Supabase.instance.client.auth.currentSession;
        final initialUserId = currentSession?.user.id;

        await RevenueCatManager.initialize(initialUserId: initialUserId);

        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);

        runApp(SentryWidget(child: MyApp()));
      } catch (e, stack) {
        debugPrint('Startup error: $e');
        debugPrint('Stack: $stack');
        await Sentry.captureException(e, stackTrace: stack);
        runApp(MaterialApp(
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (context) => Text(
                  'Startup error:\n\nError: $e\n\nStack: $stack',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ),
        ));
      }
    },
  );
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
  Future<bool>? _subscriptionFuture;
  String? _lastCheckedUserId;
  bool? _hasSeenDemo;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      DemoScreen.hasSeenDemo().then((seen) {
        if (mounted) setState(() => _hasSeenDemo = seen);
      });
    } else {
      _hasSeenDemo = true; // no demo on web
    }
  }

  Future<bool> _getSubscriptionFuture(String userId) {
    if (_subscriptionFuture == null || _lastCheckedUserId != userId) {
      _lastCheckedUserId = userId;
      _subscriptionFuture = _checkSubscriptionStatus();
    }
    return _subscriptionFuture!;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthState>(
      builder: (context, authState, child) {
        if (authState.user != null) {
          // Check subscription status before allowing access
          return FutureBuilder<bool>(
            future: _getSubscriptionFuture(authState.user!.id),
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
                return _buildMainOrOnboarding();
              } else {
                return SubscriptionRequiredScreen(
                  onSubscriptionMaybeChanged: () => setState(() {
                    _subscriptionFuture = null;
                  }),
                );
              }
            },
          );
        } else {
          if (_hasSeenDemo == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (_hasSeenDemo == false) {
            return DemoScreen(
              onComplete: () => setState(() => _hasSeenDemo = true),
            );
          }
          return AuthScreen();
        }
      },
    );
  }

  Widget _buildMainOrOnboarding() {
    return MainScreen();
  }

  static const String _subscriptionCacheKey = 'rwa_subscription_active';

  Future<bool> _checkSubscriptionStatus() async {
    try {
      final isSubscribed = await RevenueCatManager.isSubscribed();
      final trialStatus = await RevenueCatManager.getTrialStatus();
      final result = isSubscribed || (trialStatus['isInTrial'] == true);

      // Persist so a network error does not lock out a paying user
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_subscriptionCacheKey, result);

      return result;
    } catch (e, stack) {
      debugPrint('Error checking subscription status: $e');
      Sentry.captureException(e, stackTrace: stack);

      // Fall back to last-known status rather than failing closed
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_subscriptionCacheKey) ?? false;
    }
  }
}

class AuthScreen extends StatefulWidget {
  @override
  AuthScreenState createState() => AuthScreenState();
}

class AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showPasswordResetDialog(BuildContext context) {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Enter your email address and we\'ll send you a password reset link.'),
            SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: AppThemes.getInputDecoration(context).copyWith(
                labelText: 'Email',
                hintText: 'your@email.com',
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter your email address')),
                );
                return;
              }

              try {
                await Supabase.instance.client.auth.resetPasswordForEmail(
                  emailController.text.trim(),
                );

                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Password reset email sent! Check your inbox.')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ErrorMessages.userFriendlyAuthMessage(e))),
                );
              }
            },
            child: Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      AuthResponse? response;
      final doSignUp = _isSignUp && !kIsWeb; // Web is sign-in only
      if (doSignUp) {
        response = await signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        response = await signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (!mounted) return;

      if (response?.user != null) {
        if (doSignUp && response?.session == null) {
          // Signup succeeded but email confirmation required
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Account created! Please check your email to confirm, then sign in.'),
              duration: Duration(seconds: 5),
            ),
          );
          setState(() => _isSignUp = false);
        }
        // Otherwise AuthState will handle navigation
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(doSignUp
                ? 'Failed to create account. Please try again.'
                : 'Invalid email or password. Please try again.'),
          ),
        );
      }
    } catch (e, stack) {
      if (!mounted) return;
      Sentry.captureException(e, stackTrace: stack);
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(ErrorMessages.userFriendlyAuthMessage(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSignUp
              ? 'Ridewealth Assistant - Sign up'
              : 'Ridewealth Assistant - Sign in',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (kIsWeb) ...[
                    WebSigninAnimation(height: 200),
                    SizedBox(height: 16),
                    const StoreDownloadBadges(),
                    SizedBox(height: 24),
                  ],
                  TextFormField(
                    key: const Key('auth_email_field'),
                    controller: _emailController,
                    decoration: AppThemes.getInputDecoration(context).copyWith(
                      labelText: 'Email',
                      hintText: 'your@email.com',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enabled: !_isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    key: const Key('auth_password_field'),
                    controller: _passwordController,
                    decoration: AppThemes.getInputDecoration(context).copyWith(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                    ),
                    obscureText: true,
                    enabled: !_isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => _showPasswordResetDialog(context),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppThemes.primaryColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                  ),
                  if (!kIsWeb) ...[
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                                _passwordController.clear();
                              });
                            },
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Sign In'
                            : 'Don\'t have an account? Sign Up',
                      ),
                    ),
                  ],
                ],
              ),
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
    final currentSession = Supabase.instance.client.auth.currentSession;
    if (currentSession?.user != null) {
      RevenueCatManager.setRevenueCatUser(currentSession!.user.id);
    }

    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      try {
        _user = data.session?.user;
        if (_user != null) {
          await createSupabaseUserDocument(_user!);
          await RevenueCatManager.setRevenueCatUser(_user!.id);
        }
        notifyListeners();
      } catch (e, stack) {
        debugPrint('Auth state change error: $e');
        Sentry.captureException(e, stackTrace: stack);
      }
    });
  }

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('rwa_subscription_active');
      _user = null;
      notifyListeners();
    } catch (e, stack) {
      debugPrint('Sign out error: $e');
      Sentry.captureException(e, stackTrace: stack);
      rethrow;
    }
  }
}

/**
 * St Michael the Archangel, pray for us
 * Mary, Mother of God, pray for us
 * St Joseph, terror of demons, pray for us
 * St Gregory the Great, pray for us
 * St Carlo Acutis, pray for us
 * Bl Michael McGivney, pray for us
 */
