import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

/// Official-style App Store and Google Play badges for web sign-in.
/// Opens links in a new browser tab.
class StoreDownloadBadges extends StatelessWidget {
  const StoreDownloadBadges({super.key});

  static final Uri _playStoreUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=com.ridewealthassistant.app',
  );
  static final Uri _appStoreUri = Uri.parse(
    'https://apps.apple.com/us/app/ridewealth-assistant/id6670771727',
  );

  static const String _googlePlayBadgeSvg =
      'https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg';
  static const String _appStoreBadge =
      'https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83';

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
                child: SvgPicture.network(
                  _googlePlayBadgeSvg,
                  height: 48,
                  fit: BoxFit.contain,
                  placeholderBuilder: (context) => const SizedBox(
                    height: 48,
                    width: 160,
                  ),
                ),
              ),
              _BadgeLink(
                label: 'Download on the App Store',
                onTap: () => _open(_appStoreUri),
                child: Image.network(
                  _appStoreBadge,
                  height: 48,
                  fit: BoxFit.contain,
                  semanticLabel: 'Download on the App Store',
                  errorBuilder: (_, __, ___) => Text(
                    'App Store',
                    style: theme.textTheme.labelLarge,
                  ),
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
