import 'package:flutter/material.dart';

class SubscriptionRequiredScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subscription Required'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Please subscribe to access the app.'),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Subscribe (Google Play)'),
              onPressed: () => print('Google Play button pressed'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              child: Text('Subscribe (App Store)'),
              onPressed: () => print('App Store button pressed'),
            ),
          ],
        ),
      ),
    );
  }
}
