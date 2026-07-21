import 'package:flutter/material.dart';

import '../../../../shared/design_system/mameroom_design_system.dart';
import '../../domain/entities/material_list_query.dart';

class MaterialSearchBar extends StatelessWidget {
  const MaterialSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onExit,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onExit;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      children: [
        Semantics(
          button: true,
          label: '\uAC80\uC0C9 \uC885\uB8CC',
          child: IconButton(
            key: const ValueKey('material-search-exit'),
            onPressed: onExit,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        const SizedBox(width: MameroomSpacing.xs),
        Expanded(
          child: TextField(
            key: const ValueKey('material-search-field'),
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText:
                  '\uC790\uB8CC\uBA85\uC744 \uC785\uB825\uD558\uC138\uC694',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : Semantics(
                      button: true,
                      label: '\uAC80\uC0C9\uC5B4 \uC9C0\uC6B0\uAE30',
                      child: IconButton(
                        key: const ValueKey('material-search-clear'),
                        onPressed: onClear,
                        icon: const Icon(Icons.cancel_rounded),
                      ),
                    ),
              filled: true,
              fillColor: colors.paper,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: MameroomSpacing.sm,
                vertical: MameroomSpacing.sm,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: MameroomRadius.mediumRadius,
                borderSide: BorderSide(color: colors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: MameroomRadius.mediumRadius,
                borderSide: BorderSide(color: colors.primary, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<MaterialSortOption?> showMaterialSortSheet({
  required BuildContext context,
  required MaterialSortOption current,
}) {
  return showModalBottomSheet<MaterialSortOption>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: context.mameroom.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(MameroomRadius.card),
      ),
    ),
    builder: (_) => _MaterialSortSheet(current: current),
  );
}

class _MaterialSortSheet extends StatefulWidget {
  const _MaterialSortSheet({required this.current});
  final MaterialSortOption current;

  @override
  State<_MaterialSortSheet> createState() => _MaterialSortSheetState();
}

class _MaterialSortSheetState extends State<_MaterialSortSheet> {
  late MaterialSortOption selected = widget.current;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 520),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          MameroomSpacing.md,
          0,
          MameroomSpacing.md,
          MameroomSpacing.md + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '\uC815\uB82C\uD558\uAE30',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: MameroomSpacing.sm),
            RadioGroup<MaterialSortOption>(
              groupValue: selected,
              onChanged: (value) => setState(() => selected = value!),
              child: Column(
                children: [
                  for (final option in MaterialSortOption.values)
                    RadioListTile<MaterialSortOption>(
                      key: ValueKey('material-sort-${option.name}'),
                      value: option,
                      title: Text(materialSortLabel(option)),
                      subtitle: Text(materialSortDescription(option)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: MameroomSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('\uCDE8\uC18C'),
                  ),
                ),
                const SizedBox(width: MameroomSpacing.sm),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('material-sort-apply'),
                    onPressed: () => Navigator.pop(context, selected),
                    child: const Text('\uC801\uC6A9\uD558\uAE30'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String materialSortLabel(MaterialSortOption option) => switch (option) {
  MaterialSortOption.newest => '\uCD5C\uC2E0\uC21C',
  MaterialSortOption.recentlyStudied => '\uCD5C\uADFC \uD559\uC2B5\uC21C',
  MaterialSortOption.name => '\uC774\uB984\uC21C',
  MaterialSortOption.oldest => '\uC624\uB798\uB41C\uC21C',
};

String materialSortDescription(MaterialSortOption option) => switch (option) {
  MaterialSortOption.newest =>
    '\uCD5C\uADFC \uC5C5\uB85C\uB4DC\uB41C \uC790\uB8CC \uC21C\uC11C',
  MaterialSortOption.recentlyStudied =>
    '\uAC00\uC7A5 \uCD5C\uADFC\uC5D0 \uD559\uC2B5\uD55C \uC790\uB8CC \uC21C\uC11C',
  MaterialSortOption.name => '\uC790\uB8CC\uBA85 \uAC00\uB098\uB2E4\uC21C',
  MaterialSortOption.oldest =>
    '\uC624\uB798 \uC804\uC5D0 \uC5C5\uB85C\uB4DC\uB41C \uC790\uB8CC \uC21C\uC11C',
};
