import 'package:flutter/material.dart';

import '../design_system/theme/mameroom_theme_extension.dart';

class MameroomShell extends StatelessWidget {
  const MameroomShell({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
    this.showSparkles = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showSparkles;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Scaffold(
      backgroundColor: colors.paper,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.paper,
              colors.primaryMist.withValues(alpha: 0.34),
              colors.cloud,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              if (showSparkles) const Positioned.fill(child: _SparkleField()),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(
                    padding: padding,
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MameroomPrimaryButton extends StatelessWidget {
  const MameroomPrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );

    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
    );
  }
}

class MameroomTextField extends StatelessWidget {
  const MameroomTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.suffixIcon,
    this.onFieldSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class MameroomDots extends StatelessWidget {
  const MameroomDots({required this.count, required this.activeIndex, super.key});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == activeIndex ? 9 : 7,
          height: index == activeIndex ? 9 : 7,
          decoration: BoxDecoration(
            color: index == activeIndex ? colors.primary : colors.primaryMist,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _SparkleField extends StatelessWidget {
  const _SparkleField();

  @override
  Widget build(BuildContext context) {
    final colors = context.mameroom;
    const positions = [
      (0.10, 0.12, 10.0),
      (0.22, 0.27, 6.0),
      (0.82, 0.18, 8.0),
      (0.76, 0.40, 6.0),
      (0.18, 0.68, 7.0),
      (0.88, 0.74, 9.0),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: positions.map((position) {
            return Positioned(
              left: constraints.maxWidth * position.$1,
              top: constraints.maxHeight * position.$2,
              child: Icon(
                Icons.auto_awesome,
                size: position.$3,
                color: colors.primarySoft.withValues(alpha: 0.48),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
