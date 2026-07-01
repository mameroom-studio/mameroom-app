import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_bootstrap.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!SupabaseBootstrap.isInitialized) {
    return null;
  }

  return Supabase.instance.client;
});