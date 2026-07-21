import 'package:flutter/material.dart';

class MameroomDropdown<T> extends StatelessWidget {
  const MameroomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items.entries
          .map(
            (entry) =>
                DropdownMenuItem<T>(value: entry.key, child: Text(entry.value)),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class MameroomSwitch extends StatelessWidget {
  const MameroomSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) =>
      Switch(value: value, onChanged: onChanged);
}

class MameroomCheckbox extends StatelessWidget {
  const MameroomCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) =>
      Checkbox(value: value, onChanged: onChanged);
}

class MameroomChipGroup<T> extends StatelessWidget {
  const MameroomChipGroup({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  final Map<T, String> items;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.entries.map((entry) {
        return ChoiceChip(
          label: Text(entry.value),
          selected: entry.key == selected,
          onSelected: (_) => onSelected(entry.key),
        );
      }).toList(),
    );
  }
}
