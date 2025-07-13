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
import 'package:flutter_svg/flutter_svg.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialize Supabase FIRST
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseKey,
    );

    // THEN initialize feature flags
    await FeatureFlags.initialize();
    
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
            OAuthButton(
              text: 'Continue with Google',
              backgroundColor: Colors.white,
              textColor: Colors.black87,
              borderColor: const Color(0xFFE0E0E0),
              icon: SvgPicture.asset(
                'assets/google_g.svg',
                height: 24,
                width: 24,
              ),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final result = await signInWithGoogle();
                if (!mounted) return;
                if (!result) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Failed to sign in with Google. Please try again.')),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            OAuthButton(
              text: 'Continue with Apple',
              backgroundColor: Colors.black,
              textColor: Colors.white,
              borderColor: Colors.black,
              icon: Icon(Icons.apple, color: Colors.white, size: 24),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final result = await signInWithApple();
                if (!mounted) return;
                if (!result) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Failed to sign in with Apple. Please try again.')),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            OAuthButton(
              text: 'Sign in with Email/Password',
              backgroundColor: Colors.white,
              textColor: Colors.black87,
              borderColor: const Color(0xFFE0E0E0),
              icon: Icon(Icons.mail_outline, color: Colors.black87, size: 24),
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

class OAuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Widget? icon;
  final Color borderColor;

  const OAuthButton({
    required this.text,
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
    this.borderColor = const Color(0xFF1565C0), // Stronger blue
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 48,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF42A5F5).withOpacity(0.35), // Brighter blue shadow
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(12),
        ),
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            side: BorderSide(color: borderColor, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 12),
              ],
              Text(text, style: TextStyle(color: textColor)),
            ],
          ),
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
      print('DEBUG: AuthState user: ${_user}');
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