import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/supabase/supabase_client_provider.dart';
import '../data/support_repository.dart';
import '../domain/support_inquiry.dart';

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) throw StateError('Supabase client is not initialized.');
  return SupabaseSupportRepository(client);
});

final supportInquiriesProvider = FutureProvider<List<SupportInquiry>>(
  (ref) => ref.watch(supportRepositoryProvider).loadMine(),
);

final supportInquiryProvider = FutureProvider.family<SupportInquiry?, String>(
  (ref, id) => ref.watch(supportRepositoryProvider).loadMineById(id),
);
