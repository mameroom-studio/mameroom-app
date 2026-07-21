import 'package:flutter/material.dart';

class OpenSourceLicensePage extends StatelessWidget {
  const OpenSourceLicensePage({super.key});
  static const routePath = '/settings/licenses';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('오픈소스 라이선스')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.code_rounded, size: 56),
              const SizedBox(height: 20),
              const Text(
                'Mameroom은 다양한 오픈소스 소프트웨어를\n사용하여 제작되었습니다.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const ValueKey('show-licenses'),
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: 'Mameroom',
                ),
                child: const Text('라이선스 보기'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
