import 'package:flutter/material.dart';
import '../theme/app_themes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'export_screen.dart';
import 'disclaimer_screen.dart';
import 'contact_screen.dart';
import 'profile_screen.dart';

class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  bool showConfirmation = false;

  void openConfirmation() {
    setState(() {
      showConfirmation = true;
    });
  }

  void closeConfirmation() {
    setState(() {
      showConfirmation = false;
    });
  }

  Future<void> handleSignOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You have been signed out.')),
      );
      Navigator.of(context).pushReplacementNamed('/');
    } catch (error) {
      print('Error signing out: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out. Please try again.')),
      );
    }
    closeConfirmation();
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
    final user = Provider.of<AuthState>(context).user;

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
              SizedBox(height: 24),
              _buildButton(
                'Sign Out',
                openConfirmation,
                color: Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
