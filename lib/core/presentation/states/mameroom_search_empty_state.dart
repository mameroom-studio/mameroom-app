import 'package:flutter/material.dart';

import 'mameroom_state_view.dart';

class MameroomSearchEmptyState extends StatelessWidget {
  const MameroomSearchEmptyState({
    super.key,
    this.keyword,
    this.onSuggestionPressed,
    this.size = MameroomStateSize.medium,
  });

  final String? keyword;
  final ValueChanged<String>? onSuggestionPressed;
  final MameroomStateSize size;

  @override
  Widget build(BuildContext context) {
    return MameroomStateView(
      variant: MameroomStateVariant.search,
      title: '\uAC80\uC0C9 \uACB0\uACFC\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.',
      description: keyword == null || keyword!.isEmpty
          ? '\uB2E4\uB978 \uD0A4\uC6CC\uB4DC\uB85C \uAC80\uC0C9\uD574\uBCF4\uC138\uC694.'
          : '"$keyword"\uC5D0 \uB9DE\uB294 \uACB0\uACFC\uB97C \uCC3E\uC9C0 \uBABB\uD588\uC5B4\uC694.',
      pixelIcon: MameroomStatePixelIcon.search,
      suggestionChips: const [
        '\uD68C\uACC4',
        '\uAE08\uC735',
        '\uACBD\uC81C',
        '\uB9C8\uCF00\uD305',
        '\uC218\uD559',
        '\uC5B8\uC5B4',
      ],
      onChipPressed: onSuggestionPressed,
      size: size,
    );
  }
}
