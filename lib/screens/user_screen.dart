import 'package:flutter/material.dart';
import '../theme/app_themes.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'export_screen.dart';
import 'disclaimer_screen.dart';
import 'contact_screen.dart';
import 'profile_screen.dart';

class UserScreen extends StatefulWidget {
  @override
  UserScreenState createState() => UserScreenState();
}

class UserScreenState extends State<UserScreen> {
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About RideWealth Assistant'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RideWealth Assistant',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text('Version 1.0.18'),
              SizedBox(height: 16),
              Text(
                'A financial assistant for rideshare and gig economy drivers to track mileage, income, expenses, and calculate quarterly estimated tax obligations.',
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 8),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DisclaimerScreen()),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Disclaimer',
                    style: TextStyle(
                      color: AppThemes.primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ContactScreen()),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Contact Support',
                    style: TextStyle(
                      color: AppThemes.primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                '© ${DateTime.now().year} RideWealth Assistant',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> handleSignOut(BuildContext context) async {
    print("Sign out button pressed");
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final authState = Provider.of<AuthState>(context, listen: false);
    try {
      await supabase.Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      print("Supabase sign out successful");

      // Update AuthState
      await authState.signOut();
      if (!mounted) return;
      print("AuthState updated");

      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('You have been signed out.')),
      );
      print("Snackbar shown");

      // Navigate back to the main screen
      navigator.pushReplacementNamed('/');
      print("Navigation attempted");
    } catch (error) {
      print('Error signing out: $error');
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error signing out. Please try again.')),
      );
    }
  }

  Widget _buildButton(String text, VoidCallback onPressed, {Color? color}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppThemes.primaryColor,
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to Your User Dashboard',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              Text('Please select an option from the menu below.'),
              SizedBox(height: 24),
              _buildButton(
                'User Profile',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                ),
              ),
              SizedBox(height: 12),
              _buildButton(
                'Exports',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ExportScreen()),
                ),
              ),
              SizedBox(height: 12),
              _buildButton(
                'Disclaimer',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DisclaimerScreen()),
                ),
              ),
              SizedBox(height: 12),
              _buildButton(
                'Contact',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ContactScreen()),
                ),
              ),
              SizedBox(height: 12),
              _buildButton(
                'About',
                () => _showAboutDialog(context),
              ),
              SizedBox(height: 24),
              _buildButton(
                'Sign Out',
                () => handleSignOut(context),
                color: Theme.of(context).colorScheme.error,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
