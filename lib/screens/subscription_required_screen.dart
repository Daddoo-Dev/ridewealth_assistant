import 'package:flutter/material.dart';
import '../services/feature_flag_service.dart';
import './main_screen.dart';

class SubscriptionRequiredScreen extends StatelessWidget {
  const SubscriptionRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // If subscription screens are disabled, redirect to main content
    if (!FeatureFlags.subscriptionRequiredScreenEnabled) {
      return MainScreen(); // Removed const as MainScreen might need state 
    }
    
    // Add your existing subscription screen UI here
    return Scaffold(
      body: Center(
        child: Text('Subscription Required'),
      ),
    );
  }
} 