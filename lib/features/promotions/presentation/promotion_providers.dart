import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/supabase/supabase_client_provider.dart';
import '../data/promotion_repository.dart';

final promotionRepositoryProvider = Provider<PromotionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError('Supabase client is not initialized.');
  return SupabasePromotionRepository(client);
});
