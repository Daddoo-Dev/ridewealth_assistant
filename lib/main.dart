import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:provider/provider.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/main_screen.dart';
import 'theme/app_themes.dart';
import 'theme/theme_provider.dart';
import 'firebase_options.dart';
import 'subscription_manager.dart';
import 'screens/privacy_policy.dart';
import 'subscription_required.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  if (Firebase.apps.isEmpty) {
    print(
        'Firebase initialization failed. The app may not function correctly.');
  } else {
    if (!kIsWeb) {
      // Mobile-specific initialization
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    }
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthState()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: MyApp(),
    ),
  );
}

Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    if (!kIsWeb) {
      await FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
    }
  }
}

class AuthState extends ChangeNotifier {
  User? user;
  bool isLoading = true;

  AuthState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      this.user = user;
      isLoading = false;
      notifyListeners();
    }, onError: (error) {
      print('Error in auth state changes: $error');
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(error, StackTrace.current);
      }
      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    user = null;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthState, ThemeProvider>(
      builder: (context, authState, themeProvider, _) {
        if (authState.isLoading) {
          return MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        return MaterialApp(
          title: 'RideWealth Assistant',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: themeProvider.themeMode,
          home: authState.user != null ? AuthenticationWrapper() : AuthScreen(),
          routes: {
            '/privacy_policy': (context) => PrivacyPolicyPage(),
          },
        );
      },
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    print('AuthenticationWrapper build method called');
    print('User ID: $userId');
    return FutureBuilder<void>(
      future: Future.wait([
        SubscriptionManager.checkAndStartFreeTrial(userId),
        SubscriptionManager.checkAndRenewSubscription(userId),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return FutureBuilder<bool>(
            future: SubscriptionManager.isSubscriptionActive(userId),
            builder: (context, subscriptionSnapshot) {
              if (subscriptionSnapshot.hasData) {
                print('Subscription active: ${subscriptionSnapshot.data}');
                if (subscriptionSnapshot.data!) {
                  return MainScreen();
                } else {
                  return SubscriptionRequiredScreen(); // This now uses the imported class
                }
              } else {
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
            },
          );
        } else {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }
}

class AuthScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _createUserDocument(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      await userDoc.set({
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        // Add any other initial fields you want for new users
      });
    } else {
      await userDoc.update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<UserCredential?> _signInWithGoogle() async {
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
        await _createUserDocument(userCredential.user!);
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

  Future<UserCredential?> _signInWithApple() async {
    try {
      final rawNonce = generateNonce();
      final nonce = sha256ofString(rawNonce);

      if (kIsWeb) {
        final provider = OAuthProvider("apple.com")
          ..addScope('email')
          ..addScope('name')
          ..setCustomParameters({
            'nonce': nonce,
          });

        print('Attempting to sign in with Apple on Web');
        final result = await FirebaseAuth.instance.signInWithPopup(provider);
        print('Web Apple Sign In successful: ${result.user?.uid}');

        if (result.user != null) {
          await _createUserDocument(result.user!);
        }

        return result;
      } else {
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonce,
        );

        print(
            'Received Apple credential: ${appleCredential.identityToken != null}');

        final oauthCredential = OAuthProvider("apple.com").credential(
          idToken: appleCredential.identityToken,
          rawNonce: rawNonce,
        );

        final authResult =
            await FirebaseAuth.instance.signInWithCredential(oauthCredential);
        print('Firebase sign in successful: ${authResult.user?.uid}');

        if (authResult.user != null) {
          await _createUserDocument(authResult.user!);
        }

        return authResult;
      }
    } catch (e) {
      print('Detailed error signing in with Apple: $e');
      if (!kIsWeb) {
        await FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
      }
      return null;
    }
  }

  Future<UserCredential?> _signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      if (userCredential.user != null) {
        await _createUserDocument(userCredential.user!);
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

  Future<void> forceSendLogs() async {
    await FirebaseCrashlytics.instance.sendUnsentReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign In')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('Sign in with Google'),
              onPressed: () async {
                try {
                  final result = await _signInWithGoogle();
                  if (result == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Failed to sign in with Google. Please try again.')),
                    );
                  }
                } catch (e) {
                  FirebaseCrashlytics.instance
                      .log('Error in Google Sign In button press: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'An error occurred during Google Sign In. Please try again.')),
                  );
                } finally {
                  await forceSendLogs();
                }
              },
            ),
            ElevatedButton(
              child: Text('Sign in with Apple'),
              onPressed: () async {
                final result = await _signInWithApple();
                if (result == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Failed to sign in with Apple. Please try again.')),
                  );
                }
              },
            ),
            ElevatedButton(
              child: Text('Sign in with Email/Password'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => EmailPasswordDialog(
                    onSignIn: _signInWithEmailAndPassword,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class EmailPasswordDialog extends StatefulWidget {
  final Future<UserCredential?> Function(String email, String password)
      onSignIn;

  EmailPasswordDialog({required this.onSignIn});

  @override
  State<EmailPasswordDialog> createState() => _EmailPasswordDialogState();
}

class _EmailPasswordDialogState extends State<EmailPasswordDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Sign In'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: Text('Sign In'),
          onPressed: () async {
            final result = await widget.onSignIn(
              _emailController.text,
              _passwordController.text,
            );
            if (result == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Failed to sign in. Please check your credentials and try again.')),
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
