/// Maps auth/API error codes and message substrings to user-friendly text.
/// Add entries for any error you want to show a clear, professional message.
class ErrorMessages {
  ErrorMessages._();

  static const String _default = 'Something went wrong. Please try again.';

  /// Keys are substrings to match in error message (case-insensitive).
  /// First match wins; put more specific strings before generic ones.
  static const Map<String, String> auth = {
    'Invalid login credentials':
        'Your email and/or password was incorrect. Please try again with the correct credentials.',
    'invalid_credentials':
        'Your email and/or password was incorrect. Please try again with the correct credentials.',
    'Invalid login credential':
        'Your email and/or password was incorrect. Please try again with the correct credentials.',
    'Email not confirmed':
        'Please confirm your email address using the link we sent you, then try again.',
    'email_not_confirmed':
        'Please confirm your email address using the link we sent you, then try again.',
    'User not found':
        'No account found with this email. Please check the address or sign up.',
    'user_not_found':
        'No account found with this email. Please check the address or sign up.',
    'Signup disabled':
        'New accounts are not available for this app. Please sign in with an existing account.',
    'signup_disabled':
        'New accounts are not available for this app. Please sign in with an existing account.',
    'Password should be at least':
        'Your password does not meet the requirements. Please use at least 6 characters.',
    'weak_password':
        'Your password does not meet the requirements. Please use a stronger password.',
    'Email rate limit':
        'Too many attempts. Please wait a few minutes before trying again.',
    'rate_limit':
        'Too many attempts. Please wait a few minutes before trying again.',
    'network': 'Please check your internet connection and try again.',
    'Connection': 'Please check your internet connection and try again.',
  };

  /// Returns a user-friendly message for auth errors. Log the raw [error] for debugging.
  static String userFriendlyAuthMessage(dynamic error) {
    if (error == null) return _default;
    final String raw = error is Exception ? error.toString() : error.toString();
    final String lower = raw.toLowerCase();
    for (final entry in auth.entries) {
      if (lower.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return _default;
  }
}
