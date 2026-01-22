class Environment {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  
  // Support both SUPABASE_ANON_PUBLIC (local) and SUPABASE_KEY (CI)
  static const String _anonPublic = String.fromEnvironment(
    'SUPABASE_ANON_PUBLIC',
    defaultValue: '',
  );
  static const String _key = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: '',
  );
  
  // Use SUPABASE_ANON_PUBLIC if provided, otherwise fallback to SUPABASE_KEY
  static String get supabaseKey {
    return _anonPublic != '' ? _anonPublic : _key;
  }
}