import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  const Env._();

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabasePublishableKey {
    return dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '';
  }

  static String get appEnv => dotenv.env['APP_ENV'] ?? 'local';

  static bool get isProduction {
    final value = appEnv.toLowerCase().trim();
    return value == 'production' || value == 'prod';
  }

  static bool get shouldShowOnboarding {
    if (isProduction) {
      return true;
    }

    final value = dotenv.env['SHOW_ONBOARDING']?.toLowerCase().trim();
    if (value == null || value.isEmpty) {
      return false;
    }
    return value == 'true' || value == '1' || value == 'yes' || value == 'on';
  }

  static bool get hasSupabaseConfig {
    return supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
  }
}