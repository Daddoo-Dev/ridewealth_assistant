import 'package:shared_preferences/shared_preferences.dart';

/// Lets a brand-new user use the real app (log real trips, expenses, income)
/// before the subscription paywall interrupts them, instead of gating
/// everything immediately after signup with zero product experience.
///
/// The paywall is only shown once BOTH conditions are true: the signup-date
/// grace window has elapsed AND the user has logged enough real entries to
/// have actually relied on the app. A light user who signed up 3 weeks ago
/// but never used it stays ungated until they do; a heavy user who logs 10
/// entries on day one still isn't asked to pay until the window passes.
abstract final class GracePeriodService {
  static const int graceDays = 7;
  static const int usageMinimum = 3;
  static const String _usageCountKey = 'rwa_usage_count';

  /// Call after any real record is created (mileage trip, expense, income).
  static Future<void> recordUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_usageCountKey) ?? 0;
    await prefs.setInt(_usageCountKey, count + 1);
  }

  /// Whether an unsubscribed user should still get full access.
  static Future<bool> hasAccess(String createdAt) async {
    final signupDate = DateTime.tryParse(createdAt);
    if (signupDate == null) return true; // don't block on unparseable data

    final daysSinceSignup = DateTime.now().difference(signupDate).inDays;
    final withinGracePeriod = daysSinceSignup < graceDays;

    final prefs = await SharedPreferences.getInstance();
    final usageCount = prefs.getInt(_usageCountKey) ?? 0;
    final belowUsageMinimum = usageCount < usageMinimum;

    return withinGracePeriod || belowUsageMinimum;
  }
}
