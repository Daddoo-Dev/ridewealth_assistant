// Integration tests for auth and subscription flows.
// Run: flutter test integration_test/app_flow_test.dart
// With Supabase (required for any test that starts the app):
//   --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_PUBLIC=...
// Subscribed/Unsubscribed tests run only when credentials are passed:
//   -d TEST_SUBSCRIBED_EMAIL=... -d TEST_SUBSCRIBED_PASSWORD=...
//   -d TEST_FREE_EMAIL=... -d TEST_FREE_PASSWORD=...

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ridewealth_assistant/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth and Subscription Flows', () {
    testWidgets('Unauthenticated user sees Sign In screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('auth_email_field')), findsOneWidget);
      expect(find.byKey(const Key('auth_password_field')), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
    });

    testWidgets('Invalid login shows error message', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('auth_email_field')), 'invalid@test.com');
      await tester.enterText(
          find.byKey(const Key('auth_password_field')), 'wrongpassword');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(
        find.text('Invalid email or password. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Subscribed user sees main app after sign in',
      (tester) async {
        const email = String.fromEnvironment(
          'TEST_SUBSCRIBED_EMAIL',
          defaultValue: '',
        );
        const password = String.fromEnvironment(
          'TEST_SUBSCRIBED_PASSWORD',
          defaultValue: '',
        );
        if (email.isEmpty || password.isEmpty) return;

        app.main();
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byKey(const Key('auth_email_field')), email);
        await tester.enterText(
            find.byKey(const Key('auth_password_field')), password);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        expect(find.text('RideWealth Assistant'), findsOneWidget);
        expect(find.text('Home'), findsOneWidget);
      },
      skip: const String.fromEnvironment('TEST_SUBSCRIBED_EMAIL',
              defaultValue: '')
          .isEmpty,
    );

    testWidgets(
      'Unsubscribed user sees Premium Features screen after sign in',
      (tester) async {
        const email = String.fromEnvironment(
          'TEST_FREE_EMAIL',
          defaultValue: '',
        );
        const password = String.fromEnvironment(
          'TEST_FREE_PASSWORD',
          defaultValue: '',
        );
        if (email.isEmpty || password.isEmpty) return;

        app.main();
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byKey(const Key('auth_email_field')), email);
        await tester.enterText(
            find.byKey(const Key('auth_password_field')), password);
        await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
        await tester.pumpAndSettle(const Duration(seconds: 5));

        expect(find.text('Premium Features'), findsOneWidget);
        expect(find.text('Choose Your Plan'), findsOneWidget);
      },
      skip: const String.fromEnvironment('TEST_FREE_EMAIL', defaultValue: '')
          .isEmpty,
    );
  });
}
