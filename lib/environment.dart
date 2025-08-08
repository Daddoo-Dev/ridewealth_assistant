abstract class Environment {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  
  // New publishable key - safe to expose in source code
  static const String supabaseKey = 'sb_publishable_cLW1iQZTlC9CLP4HQ4-Heg_QyyyEZy0';
  
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );
}