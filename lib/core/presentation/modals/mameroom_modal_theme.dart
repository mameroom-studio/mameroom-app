import 'package:flutter/material.dart';

import '../../../shared/design_system/theme/mameroom_theme_extension.dart';

enum MameroomModalVariant {
  info,
  success,
  warning,
  error,
  confirm,
  reward,
  levelUp,
  seedGrowth,
  purchase,
  loading,
  empty,
  networkError,
}

enum MameroomModalSize { small, medium, large }

enum MameroomModalButtonVariant {
  primary,
  secondary,
  warning,
  destructive,
  disabled,
}

class MameroomModalPalette {
  const MameroomModalPalette({
    required this.accent,
    required this.soft,
    required this.iconData,
  });

  final Color accent;
  final Color soft;
  final IconData iconData;
}

extension MameroomModalVariantTheme on MameroomModalVariant {
  MameroomModalPalette palette(BuildContext context) {
    final colors = context.mameroom;
    return switch (this) {
      MameroomModalVariant.success => MameroomModalPalette(
        accent: colors.seedGreen,
        soft: colors.seedGreen.withValues(alpha: 0.18),
        iconData: Icons.check_circle_rounded,
      ),
      MameroomModalVariant.warning => const MameroomModalPalette(
        accent: Color(0xFFFFB54D),
        soft: Color(0xFFFFF0D8),
        iconData: Icons.warning_amber_rounded,
      ),
      MameroomModalVariant.error => const MameroomModalPalette(
        accent: Color(0xFFFF668B),
        soft: Color(0xFFFFE8EE),
        iconData: Icons.close_rounded,
      ),
      MameroomModalVariant.confirm => MameroomModalPalette(
        accent: colors.primarySoft,
        soft: colors.primaryMist.withValues(alpha: 0.46),
        iconData: Icons.question_mark_rounded,
      ),
      MameroomModalVariant.reward => const MameroomModalPalette(
        accent: Color(0xFFFFB54D),
        soft: Color(0xFFFFF0D8),
        iconData: Icons.card_giftcard_rounded,
      ),
      MameroomModalVariant.levelUp => MameroomModalPalette(
        accent: colors.primary,
        soft: colors.primaryMist.withValues(alpha: 0.5),
        iconData: Icons.auto_awesome_rounded,
      ),
      MameroomModalVariant.seedGrowth => MameroomModalPalette(
        accent: colors.seedGreen,
        soft: colors.seedGreen.withValues(alpha: 0.15),
        iconData: Icons.eco_rounded,
      ),
      MameroomModalVariant.purchase => MameroomModalPalette(
        accent: colors.primary,
        soft: colors.primaryMist.withValues(alpha: 0.45),
        iconData: Icons.chair_rounded,
      ),
      MameroomModalVariant.loading => MameroomModalPalette(
        accent: colors.primary,
        soft: colors.primaryMist.withValues(alpha: 0.42),
        iconData: Icons.menu_book_rounded,
      ),
      MameroomModalVariant.empty => MameroomModalPalette(
        accent: colors.primaryPale,
        soft: colors.primaryMist.withValues(alpha: 0.25),
        iconData: Icons.inventory_2_outlined,
      ),
      MameroomModalVariant.networkError => MameroomModalPalette(
        accent: colors.primary,
        soft: colors.primaryMist.withValues(alpha: 0.42),
        iconData: Icons.wifi_off_rounded,
      ),
      MameroomModalVariant.info => MameroomModalPalette(
        accent: colors.primary,
        soft: colors.primaryMist.withValues(alpha: 0.5),
        iconData: Icons.info_rounded,
      ),
    };
  }
}

double mameroomModalMaxWidth(MameroomModalSize size, double screenWidth) {
  final safeWidth = screenWidth - 48;
  final target = switch (size) {
    MameroomModalSize.small => 320.0,
    MameroomModalSize.medium => 368.0,
    MameroomModalSize.large => 460.0,
  };
  return safeWidth.clamp(280.0, target);
}
