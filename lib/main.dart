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
    // You might want to show an error dialog here
  }
}

class AuthState extends ChangeNotifier {
  User? user;

  AuthState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      this.user = user;
      notifyListeners();
    });
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthState, ThemeProvider>(
      builder: (context, authState, themeProvider, _) {
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
      return await _auth.signInWithCredential(oauthCredential);
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
                await _signInWithGoogle();
              },
            ),
            ElevatedButton(
              child: Text('Sign in with Apple'),
              onPressed: () async {
                await _signInWithApple();
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
            await widget.onSignIn(
                _emailController.text, _passwordController.text);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
