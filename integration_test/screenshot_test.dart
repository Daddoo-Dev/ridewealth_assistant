import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ridewealth_assistant/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

const _screenshotDir = String.fromEnvironment(
  'SCREENSHOT_DIR',
  defaultValue:
      '/home/daddoodev/Documents/github/ridewealth_assistant/fastlane/metadata/android/en-US/images/phoneScreenshots',
);

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  int seconds = 25,
}) async {
  for (var i = 0; i < seconds * 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) return;
  }
  throw TestFailure('Timed out waiting for $finder');
}

Future<void> _dismissKeyboard(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _shot(WidgetTester tester, String name) async {
  await _dismissKeyboard(tester);
  await tester.pump(const Duration(milliseconds: 400));

  await tester.runAsync(() async {
    final renderView = tester.binding.renderViews.first;
    final layer = renderView.layer;
    if (layer is! OffsetLayer) {
      throw StateError('RenderView layer is $layer, expected OffsetLayer');
    }
    final image = await layer.toImage(renderView.paintBounds);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Failed to encode $name.png');
    }
    final dir = Directory(_screenshotDir);
    await dir.create(recursive: true);
    final file = File('${dir.path}/$name.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    debugPrint('Wrote ${file.path} ${image.width}x${image.height}');
  });
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Capture store screenshots', (tester) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Linux has no RevenueCat plugin; keep the review account unlocked
    // via the same cache the app uses when billing is unreachable.
    await prefs.setBool('rwa_subscription_active', true);

    app.main();
    await _waitFor(tester, find.byKey(const Key('demo_next_button')));

    await tester.enterText(
      find.byKey(const Key('demo_start_mileage_field')),
      '25432',
    );
    await _shot(tester, '01_start_mileage');

    await tester.tap(find.byKey(const Key('demo_next_button')));
    await tester.pump(const Duration(milliseconds: 800));

    await tester.enterText(
      find.byKey(const Key('demo_expense_desc_field')),
      'Conoco',
    );
    await tester.enterText(
      find.byKey(const Key('demo_expense_amount_field')),
      '63.46',
    );
    await _shot(tester, '02_expense');

    await tester.tap(find.byKey(const Key('demo_next_button')));
    await tester.pump(const Duration(milliseconds: 800));

    await tester.enterText(
      find.byKey(const Key('demo_income_desc_field')),
      'DoorDash',
    );
    await tester.enterText(
      find.byKey(const Key('demo_income_amount_field')),
      '195.27',
    );
    await _shot(tester, '03_income');

    await tester.tap(find.byKey(const Key('demo_next_button')));
    await tester.pump(const Duration(milliseconds: 800));

    await tester.enterText(
      find.byKey(const Key('demo_end_mileage_field')),
      '25525',
    );
    await _shot(tester, '04_end_mileage');

    await tester.tap(find.byKey(const Key('demo_next_button')));
    await tester.pump(const Duration(milliseconds: 800));
    await _shot(tester, '05_tax_estimate');

    const email = String.fromEnvironment('APP_REVIEW_SIGNIN_EMAIL');
    const password = String.fromEnvironment('APP_REVIEW_SIGNIN_PASSWORD');

    await tester.tap(find.byKey(const Key('demo_skip_button')));
    await _waitFor(
      tester,
      find.byKey(const Key('auth_email_field')),
      seconds: 15,
    );

    if (email.isEmpty || password.isEmpty) return;

    await tester.enterText(find.byKey(const Key('auth_email_field')), email);
    await tester.enterText(
      find.byKey(const Key('auth_password_field')),
      password,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    for (var i = 0; i < 50; i++) {
      await tester.pump(const Duration(milliseconds: 400));
      if (find.text('Home').evaluate().isNotEmpty) break;
    }

    if (find.text('Home').evaluate().isEmpty) {
      debugPrint(
        'Review account signed in but Home never appeared (no RevenueCat on Linux).',
      );
      return;
    }

    await _shot(tester, '06_home');

    await tester.tap(find.text('Mileage'));
    await tester.pump(const Duration(milliseconds: 1500));
    await _shot(tester, '07_mileage');

    await tester.tap(find.text('Taxes'));
    await tester.pump(const Duration(milliseconds: 1500));
    final period = find.byType(DropdownButtonFormField<String>);
    if (period.evaluate().isNotEmpty) {
      await tester.tap(period);
      await tester.pump(const Duration(milliseconds: 800));
      final now = DateTime.now();
      final quarter = ((now.month - 1) ~/ 3) + 1;
      final option = find.text('Q$quarter ${now.year}');
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option.last);
        await tester.pump(const Duration(milliseconds: 2000));
      }
    }
    await _shot(tester, '08_taxes');
  });
}
