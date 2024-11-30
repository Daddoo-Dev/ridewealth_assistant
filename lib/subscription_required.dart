import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'main.dart' show AuthState;

class SubscriptionRequiredScreen extends StatelessWidget {
  static const String playStoreUrl = ''; // Your Play Store URL
  static const String appStoreUrl = ''; // Your App Store URL

  Future<void> _launchStore(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      print('Could not launch $url');
    }
  }

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
            if (kIsWeb)
              Text('Please install our mobile app to subscribe.')
            else if (Platform.isAndroid)
              ElevatedButton(
                child: Text('Subscribe on Google Play'),
                onPressed: () => _launchStore(playStoreUrl),
              )
            else if (Platform.isIOS)
                ElevatedButton(
                  child: Text('Subscribe on App Store'),
                  onPressed: () => _launchStore(appStoreUrl),
                ),
            SizedBox(height: 20),
            TextButton(
              child: Text('Log Out'),
              onPressed: () {
                Provider.of<AuthState>(context, listen: false).signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}