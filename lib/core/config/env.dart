import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  const Env._();

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabasePublishableKey {
    return dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '';
  }

  static String get appEnv => dotenv.env['APP_ENV'] ?? 'local';

  static bool get hasSupabaseConfig {
    return supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
  }
}