import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

/// Official-style App Store and Google Play badges for web sign-in.
/// Assets are bundled so Netlify CSP (`connect-src`) does not block network fetches
/// used by [SvgPicture.network] / [Image.network] on Flutter web.
/// Opens links in a new browser tab.
class StoreDownloadBadges extends StatelessWidget {
  const StoreDownloadBadges({super.key});

  static final Uri _playStoreUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=com.ridewealthassistant.app',
  );
  static final Uri _appStoreUri = Uri.parse(
    'https://apps.apple.com/us/app/ridewealth-assistant/id6670771727',
  );

  static const String _googlePlayBadgeAsset =
      'assets/store/google_play_badge.svg';
  static const String _appStoreBadgeAsset = 'assets/store/app_store_badge.png';

  Future<void> _open(Uri uri) async {
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.titleSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Get the mobile app',
            textAlign: TextAlign.center,
            style: labelStyle,
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              _BadgeLink(
                label: 'Get it on Google Play',
                onTap: () => _open(_playStoreUri),
                child: SvgPicture.asset(
                  _googlePlayBadgeAsset,
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
              _BadgeLink(
                label: 'Download on the App Store',
                onTap: () => _open(_appStoreUri),
                child: Image.asset(
                  _appStoreBadgeAsset,
                  height: 48,
                  fit: BoxFit.contain,
                  semanticLabel: 'Download on the App Store',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeLink extends StatelessWidget {
  const _BadgeLink({
    required this.label,
    required this.onTap,
    required this.child,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: child,
      ),
    );
  }
}
