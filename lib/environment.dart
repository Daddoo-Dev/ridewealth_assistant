abstract class Environment {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ygreztutwejfiqyzdpnd.supabase.co',
  );
  
  static const String supabaseKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlncmV6dHV0d2VqZmlxeXpkcG5kIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE4MTkwODMsImV4cCI6MjA2NzM5NTA4M30.67RGB--Gp0rooa3775wz3eeOt1vD63RpgbCUVk9zHnw',
  );
  
}