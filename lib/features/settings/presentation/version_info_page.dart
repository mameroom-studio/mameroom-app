import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

final packageInfoProvider = FutureProvider<PackageInfo>(
  (_) => PackageInfo.fromPlatform(),
);

class VersionInfoPage extends ConsumerWidget {
  const VersionInfoPage({super.key});
  static const routePath = '/settings/version';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(packageInfoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('버전 정보')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: info.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, _) => const Padding(
              padding: EdgeInsets.all(24),
              child: Text('버전 정보를 불러오지 못했습니다.'),
            ),
            data: (value) => Semantics(
              label: 'Mameroom 버전 ${value.version}, 빌드 ${value.buildNumber}',
              child: Card(
                margin: const EdgeInsets.all(20),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 52),
                      const SizedBox(height: 16),
                      Text(
                        value.appName.isEmpty ? 'Mameroom' : value.appName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      Text('버전 ${value.version}'),
                      Text('빌드 ${value.buildNumber}'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
