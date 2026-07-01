import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/supabase/supabase_client_provider.dart';
import '../../data/datasources/coin_remote_data_source.dart';
import '../../data/repositories/coin_repository_impl.dart';
import '../../domain/entities/coin_wallet.dart';
import '../../domain/repositories/coin_repository.dart';
import '../../domain/usecases/coin_usecase.dart';

final coinRemoteDataSourceProvider = Provider<CoinRemoteDataSource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    throw StateError('Supabase client is not initialized.');
  }
  return CoinRemoteDataSource(client);
});

final coinRepositoryProvider = Provider<CoinRepository>((ref) {
  return CoinRepositoryImpl(
    remoteDataSource: ref.watch(coinRemoteDataSourceProvider),
  );
});

final coinUseCaseProvider = Provider<CoinUseCase>((ref) {
  return CoinUseCase(ref.watch(coinRepositoryProvider));
});

final coinWalletProvider = FutureProvider<CoinWallet>((ref) {
  return ref.watch(coinUseCaseProvider).loadWallet();
});