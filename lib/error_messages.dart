/// Maps auth/API error codes and message substrings to user-friendly text.
/// Add entries for any error you want to show a clear, professional message.
class ErrorMessages {
  ErrorMessages._();

  static const String _default = 'Something went wrong. Please try again.';

  /// Keys are substrings to match in error message (case-insensitive).
  /// First match wins; put more specific strings before generic ones.
  static const Map<String, String> auth = {
    // Invalid credentials
    'Invalid login credentials':
        'Your email and/or password was incorrect. Please try again with the correct credentials.',
    'invalid_credentials':
        'Your email and/or password was incorrect. Please try again with the correct credentials.',
    'Invalid login credential':
        'Your email and/or password was incorrect. Please try again with the correct credentials.',
    // Email not confirmed
    'Email not confirmed':
        'Please confirm your email address using the link we sent you, then try again.',
    'email_not_confirmed':
        'Please confirm your email address using the link we sent you, then try again.',
    // User not found
    'User not found':
        'No account found with this email. Please check the address or sign up.',
    'user_not_found':
        'No account found with this email. Please check the address or sign up.',
    // Email already registered
    'User already registered':
        'An account with this email already exists. Please sign in instead.',
    'already_registered':
        'An account with this email already exists. Please sign in instead.',
    'email_exists':
        'An account with this email already exists. Please sign in instead.',
    // Invalid email format
    'Unable to validate email address':
        'Please enter a valid email address.',
    'invalid_email':
        'Please enter a valid email address.',
    'not a valid email':
        'Please enter a valid email address.',
    // Signup disabled
    'Signup disabled':
        'New accounts are not available for this app. Please sign in with an existing account.',
    'signup_disabled':
        'New accounts are not available for this app. Please sign in with an existing account.',
    // Weak password
    'Password should be at least':
        'Your password must be at least 6 characters.',
    'weak_password':
        'Your password is too weak. Please use a stronger password.',
    // Rate limiting
    'Email rate limit':
        'Too many attempts. Please wait a few minutes before trying again.',
    'rate_limit':
        'Too many attempts. Please wait a few minutes before trying again.',
    'over_email_send_rate_limit':
        'Too many emails sent. Please wait a few minutes before trying again.',
    // Network errors
    'network': 'Please check your internet connection and try again.',
    'Connection': 'Please check your internet connection and try again.',
    'SocketException': 'Please check your internet connection and try again.',
    'timeout': 'The request timed out. Please check your connection and try again.',
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
