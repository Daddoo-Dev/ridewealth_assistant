import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/theme_provider.dart';
import 'theme/app_themes.dart';
import 'services/feature_flag_service.dart';
import 'authmethod.dart';

import 'screens/main_screen.dart';
import 'environment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FeatureFlags.initialize();
    
    // Initialize Supabase
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseKey,
    );
    
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    runApp(MyApp());
  } catch (e, stack) {
    // Print error to console and show a visible error widget
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
          return MainScreen();
        } else {
          return AuthScreen();
        }
      },
    );
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('Sign in with Google'),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final result = await signInWithGoogle();
                if (!mounted) return;
                if (!result) {
                  scaffoldMessenger.showSnackBar(
                      SnackBar(
                          content: Text(
                              'Failed to sign in with Google. Please try again.')),
                    );
                }
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              child: Text('Sign in with Apple'),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final result = await signInWithApple();
                if (!mounted) return;
                if (!result) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                        content: Text(
                            'Failed to sign in with Apple. Please try again.')),
                  );
                }
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              child: Text('Sign in with Email/Password'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => EmailPasswordDialog(
                    onSignIn: signInWithEmailAndPassword,
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
  final Future<AuthResponse?> Function(String email, String password) onSignIn;

  EmailPasswordDialog({required this.onSignIn});

  @override
  State<EmailPasswordDialog> createState() => EmailPasswordDialogState();
}

class EmailPasswordDialogState extends State<EmailPasswordDialog> {
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
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            final navigator = Navigator.of(context);
            final result = await widget.onSignIn(
              _emailController.text,
              _passwordController.text,
            );
            if (!mounted) return;
            if (result == null || result.user == null) {
              scaffoldMessenger.showSnackBar(
                SnackBar(
                    content: Text(
                        'Failed to sign in. Please check your credentials and try again.')),
              );
            } else {
              navigator.pop();
            }
          },
        ),
      ],
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
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      _user = data.session?.user;
      if (_user != null) {
        await createSupabaseUserDocument(_user!);
      }
      notifyListeners();
    });
  }

  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    _user = null;
    notifyListeners();
  }
}