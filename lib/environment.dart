class Environment {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseKey = String.fromEnvironment(
    'SUPABASE_ANON_PUBLIC',
    defaultValue: '',
  );
}