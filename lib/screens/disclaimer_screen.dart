import 'package:flutter/material.dart';
import '../theme/app_themes.dart';

class DisclaimerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final int currentYear = DateTime.now().year;
    final subtitleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.onSurface,
    );
    final bodyStyle = TextStyle(fontSize: 16);

    return Scaffold(
      appBar: AppThemes.buildAppBar(context, 'Legal'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RideWealth Assistant',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Disclaimer',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            SizedBox(height: 16),
            Text(
              'RideWealth Assistant is designed solely for informational purposes and does not offer tax, legal, or accounting advice. The content provided should not be construed as such advice, and reliance on it for tax, legal, or accounting matters without professional consultation is not recommended. It is advisable to seek guidance from your own tax, legal, and accounting advisors before making any decisions or transactions.',
              style: bodyStyle,
            ),
            SizedBox(height: 32),
            Divider(),
            SizedBox(height: 32),
            // Privacy Policy
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            SizedBox(height: 8),
            Text(
              'Last updated: January 14, 2025',
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
            SizedBox(height: 16),
            Text('1. Introduction', style: subtitleStyle),
            SizedBox(height: 8),
            Text(
              'Daddoo Dev ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you visit our website and use our services.',
              style: bodyStyle,
            ),
            SizedBox(height: 16),
            Text('2. Information We Collect', style: subtitleStyle),
            SizedBox(height: 8),
            Text('2.1 Information You Provide', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(
              'We collect information that you voluntarily provide to us when you:\n'
              '• Create an account for our products\n'
              '• Purchase products or services (processed through third-party payment providers)\n'
              '• Subscribe to our newsletter or mailing list\n'
              '• Fill out contact forms (name, email, message)',
              style: bodyStyle,
            ),
            SizedBox(height: 8),
            Text('2.2 Automatically Collected Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(
              'When you visit our website, we may automatically collect:\n'
              '• Device and operating system information\n'
              '• Referring website addresses\n'
              '• Pages visited and time spent on pages\n'
              '• IP address and browser information',
              style: bodyStyle,
            ),
            SizedBox(height: 8),
            Text('2.3 Cookies and Tracking Technologies', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(
              'We use cookies and similar tracking technologies to improve your experience on our website. You can control cookie preferences through your browser settings.',
              style: bodyStyle,
            ),
            SizedBox(height: 16),
            Text('3. How We Use Your Information', style: subtitleStyle),
            SizedBox(height: 8),
            Text(
              'We use the information we collect to:\n'
              '• Comply with legal obligations\n'
              '• Detect and prevent fraud or abuse\n'
              '• Improve our website and services\n'
              '• Send marketing communications (with your consent)\n'
              '• Process transactions and send confirmations\n'
              '• Respond to your inquiries and provide customer support',
              style: bodyStyle,
            ),
            SizedBox(height: 16),
            Text('4. Third-Party Services', style: subtitleStyle),
            SizedBox(height: 8),
            Text(
              'We use the following third-party services that may collect information:',
              style: bodyStyle,
            ),
            SizedBox(height: 8),
            Text('4.1 Payment Processing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(
              'RevenueCat & Stripe: Payment information is processed securely through RevenueCat and Stripe. We do not store credit card information on our servers.',
              style: bodyStyle,
            ),
            SizedBox(height: 8),
            Text('4.2 Email Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(
              'Formspree: Contact form submissions are processed through Formspree. Your email and message are transmitted securely.',
              style: bodyStyle,
            ),
            SizedBox(height: 8),
            Text('4.3 Hosting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(
              'Firebase Hosting: Our website is hosted on Google Firebase, which may collect standard web server logs.',
              style: bodyStyle,
            ),
            SizedBox(height: 8),
            Text('4.4 Analytics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(
              'We may use analytics services to understand how visitors use our site. These services may use cookies and similar technologies.',
              style: bodyStyle,
            ),
            SizedBox(height: 16),
            Text('5. Data Sharing and Disclosure', style: subtitleStyle),
            SizedBox(height: 8),
            Text(
              'We do not sell, trade, or rent your personal information to third parties. We may share information:\n'
              '• With your explicit consent\n'
              '• In connection with a business transfer or merger\n'
              '• When required by law or to protect our rights\n'
              '• With service providers who assist in our operations (payment processors, email services)',
              style: bodyStyle,
            ),
            SizedBox(height: 16),
            Text('6. Product-Specific Privacy', style: subtitleStyle),
            SizedBox(height: 8),
            Text('6.1 RideWealth Assistant - Mobile App', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(
              'RideWealth Assistant uses Supabase for authentication and data storage. Your data is stored securely in your account. We use Sentry for error tracking to improve app stability. No personal data is shared with third parties beyond what is necessary for app functionality.',
              style: bodyStyle,
            ),
            SizedBox(height: 16),
            Text('7. Data Security', style: subtitleStyle),
            SizedBox(height: 8),
            Text(
              'We implement appropriate technical and organizational security measures to protect your information. However, no method of transmission over the internet is 100% secure, and we cannot guarantee absolute security.',
              style: bodyStyle,
            ),
            SizedBox(height: 16),
            Text('8. Your Rights', style: subtitleStyle),
            SizedBox(height: 8),
            Text(
              'You have the right to:\n'
              '• Object to processing of your information\n'
              '• Opt-out of marketing communications\n'
              '• Request deletion of your information\n'
              '• Request correction of inaccurate information\n'
              '• Access the personal information we hold about you\n\n'
              'To exercise these rights, contact us at daddoodev@proton.me',
              style: bodyStyle,
            ),
            SizedBox(height: 16),
            Text('9. Children\'s Privacy', style: subtitleStyle),
            SizedBox(height: 8),
            Text(
              'Our services are not intended for children under 13. We do not knowingly collect information from children under 13. If we become aware that we have collected such information, we will take steps to delete it.',
              style: bodyStyle,
            ),
            SizedBox(height: 16),
            Text('10. International Data Transfers', style: subtitleStyle),
            SizedBox(height: 8),
            Text(
              'Your information may be transferred to and processed in countries other than your country of residence. We ensure appropriate safeguards are in place for such transfers.',
              style: bodyStyle,
            ),
            SizedBox(height: 16),
            Text('11. Changes to This Policy', style: subtitleStyle),
            SizedBox(height: 8),
            Text(
              'We may update this Privacy Policy from time to time. Changes will be posted on this page with an updated "Last updated" date. Continued use of our services after changes constitutes acceptance of the updated policy.',
              style: bodyStyle,
            ),
            SizedBox(height: 16),
            Text('12. Contact Us', style: subtitleStyle),
            SizedBox(height: 8),
            Text(
              'If you have questions about this Privacy Policy, please contact us:\n'
              '• Website: https://daddoodev.pro\n'
              '• Email: daddoodev@proton.me',
              style: bodyStyle,
            ),
            SizedBox(height: 32),
            Divider(),
            SizedBox(height: 32),
            // Terms of Use
            Text(
              'Terms of Use',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            SizedBox(height: 8),
            Text(
              'Last updated: February 12, 2026',
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
            SizedBox(height: 16),
            Text('1. Acceptance of Terms', style: subtitleStyle),
            SizedBox(height: 8),
            Text(
              'By downloading, installing, or using RideWealth Assistant ("the App"), you agree to be bound by these Terms of Use. If you do not agree, do not use the App.',
              style: bodyStyle,
            ),
            SizedBox(height: 16),
            Text('2. Description of Service', style: subtitleStyle),
            SizedBox(height: 8),
            Text(
              'RideWealth Assistant is a financial tracking tool designed to help rideshare and gig economy drivers log mileage, income, expenses, and estimate quarterly tax obligations. The App is provided for informational purposes only and does not constitute tax, legal, or financial advice.',
              style: bodyStyle,
            ),
            SizedBox(height: 16),
            Text('3. Subscriptions & Payments', style: subtitleStyle),
            SizedBox(height: 8),
            Text(
              'RideWealth Assistant offers auto-renewable subscriptions:\n\n'
              '• Monthly Subscription — billed monthly, renews automatically until cancelled.\n'
              '• Annual Subscription — billed annually, renews automatically until cancelled.\n\n'
              'Payment is charged to your Apple ID or Google Play account at confirmation of purchase. Your subscription automatically renews unless cancelled at least 24 hours before the end of the current billing period. You can manage and cancel subscriptions in your device\'s account settings.',
              style: bodyStyle,
            ),
            SizedBox(height: 16),
            Text('4. User Accounts', style: subtitleStyle),
            SizedBox(height: 8),
            Text(
              'You must create an account to use the App. You are responsible for maintaining the confidentiality of your credentials and for all activity under your account. You agree to provide accurate, current information during registration.',
              style: bodyStyle,
            ),
            SizedBox(height: 16),
            Text('5. Acceptable Use', style: subtitleStyle),
            SizedBox(height: 8),
            Text(
              'You agree not to:\n'
              '• Use the App for any unlawful purpose\n'
              '• Attempt to reverse-engineer, decompile, or tamper with the App\n'
              '• Interfere with or disrupt the App\'s servers or networks\n'
              '• Use the App to transmit harmful or malicious content',
              style: bodyStyle,
            ),
            SizedBox(height: 16),
            Text('6. Disclaimer of Warranties', style: subtitleStyle),
            SizedBox(height: 8),
            Text(
              'The App is provided "as is" and "as available" without warranties of any kind, express or implied. We do not warrant that the App will be uninterrupted, error-free, or that any defects will be corrected. Tax estimates and financial calculations are approximate and should not be relied upon as professional advice.',
              style: bodyStyle,
            ),
            SizedBox(height: 16),
            Text('7. Limitation of Liability', style: subtitleStyle),
            SizedBox(height: 8),
            Text(
              'To the maximum extent permitted by law, Daddoo Dev and its developers shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of or inability to use the App, including but not limited to loss of data, revenue, or profits.',
              style: bodyStyle,
            ),
            SizedBox(height: 16),
            Text('8. Data & Privacy', style: subtitleStyle),
            SizedBox(height: 8),
            Text(
              'Your use of the App is also governed by our Privacy Policy (above). Your data is stored securely via Supabase. You may request deletion of your account and all associated data at any time through the App.',
              style: bodyStyle,
            ),
            SizedBox(height: 16),
            Text('9. Intellectual Property', style: subtitleStyle),
            SizedBox(height: 8),
            Text(
              'All content, trademarks, logos, and intellectual property displayed in the App are the property of Daddoo Dev. You may not reproduce, distribute, or create derivative works without prior written consent.',
              style: bodyStyle,
            ),
            SizedBox(height: 16),
            Text('10. Termination', style: subtitleStyle),
            SizedBox(height: 8),
            Text(
              'We reserve the right to suspend or terminate your access to the App at any time, with or without cause, and with or without notice. Upon termination, your right to use the App ceases immediately.',
              style: bodyStyle,
            ),
            SizedBox(height: 16),
            Text('11. Changes to These Terms', style: subtitleStyle),
            SizedBox(height: 8),
            Text(
              'We may update these Terms of Use from time to time. Changes will be posted within the App with an updated date. Continued use of the App after changes constitutes acceptance of the revised terms.',
              style: bodyStyle,
            ),
            SizedBox(height: 16),
            Text('12. Contact', style: subtitleStyle),
            SizedBox(height: 8),
            Text(
              'For questions about these Terms of Use, contact us at daddoodev@proton.me.',
              style: bodyStyle,
            ),
            SizedBox(height: 32),
            Text(
              '© $currentYear RideWealth Assistant.',
              style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
