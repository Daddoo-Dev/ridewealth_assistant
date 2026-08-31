import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (
      String screenshotName,
      List<int> screenshotBytes, [
      Map<String, Object?>? args,
    ]) async {
      final file = File(
        'fastlane/metadata/android/en-US/images/phoneScreenshots/$screenshotName.png',
      );
      await file.create(recursive: true);
      await file.writeAsBytes(screenshotBytes);
      return true;
    },
  );
}
