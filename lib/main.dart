import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:provider/provider.dart';
import 'screens/main_screen.dart';
import 'theme/app_themes.dart';
import 'theme/theme_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  if (Firebase.apps.isEmpty) {
    print(
        'Firebase initialization failed. The app may not function correctly.');
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
      isLoading = false;
      notifyListeners();
    });
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
          home: authState.user != null ? MainScreen() : AuthScreen(),
        );
      },
    );
  }
}

class AuthScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<UserCredential?> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  Future<UserCredential?> _signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      return await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    } catch (e) {
      print('Error signing in with Apple: $e');
      return null;
    }
  }

  Future<UserCredential?> _signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      print('Error signing in with email and password: $e');
      return null;
    }
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
                final result = await _signInWithGoogle();
                if (result == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Failed to sign in with Google. Please try again.')),
                  );
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
  _EmailPasswordDialogState createState() => _EmailPasswordDialogState();
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
                _emailController.text, _passwordController.text);
            if (result == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        'Failed to sign in. Please check your email and password.')),
              );
            }
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
