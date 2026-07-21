import 'package:flutter/material.dart';

import '../tokens/mameroom_colors.dart';

@immutable
class MameroomTheme extends ThemeExtension<MameroomTheme> {
  const MameroomTheme({
    required this.primary,
    required this.primaryPressed,
    required this.primarySoft,
    required this.primaryPale,
    required this.primaryMist,
    required this.paper,
    required this.cloud,
    required this.line,
    required this.ink,
    required this.muted,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.coin,
    required this.seedGreen,
    required this.sun,
    required this.blossom,
    required this.wood,
  });

  final Color primary;
  final Color primaryPressed;
  final Color primarySoft;
  final Color primaryPale;
  final Color primaryMist;
  final Color paper;
  final Color cloud;
  final Color line;
  final Color ink;
  final Color muted;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color coin;
  final Color seedGreen;
  final Color sun;
  final Color blossom;
  final Color wood;

  static const light = MameroomTheme(
    primary: MameroomColors.primary,
    primaryPressed: MameroomColors.primaryPressed,
    primarySoft: MameroomColors.primarySoft,
    primaryPale: MameroomColors.primaryDisabled,
    primaryMist: MameroomColors.primaryMist,
    paper: MameroomColors.surface,
    cloud: MameroomColors.surfaceMuted,
    line: MameroomColors.border,
    ink: MameroomColors.textPrimary,
    muted: MameroomColors.textMuted,
    success: MameroomColors.success,
    warning: MameroomColors.warning,
    error: MameroomColors.error,
    info: MameroomColors.info,
    coin: MameroomColors.coin,
    seedGreen: MameroomColors.success,
    sun: MameroomColors.coin,
    blossom: Color(0xFFFB70A5),
    wood: Color(0xFF8B5E3C),
  );

  @override
  MameroomTheme copyWith({
    Color? primary,
    Color? primaryPressed,
    Color? primarySoft,
    Color? primaryPale,
    Color? primaryMist,
    Color? paper,
    Color? cloud,
    Color? line,
    Color? ink,
    Color? muted,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? coin,
    Color? seedGreen,
    Color? sun,
    Color? blossom,
    Color? wood,
  }) {
    return MameroomTheme(
      primary: primary ?? this.primary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      primarySoft: primarySoft ?? this.primarySoft,
      primaryPale: primaryPale ?? this.primaryPale,
      primaryMist: primaryMist ?? this.primaryMist,
      paper: paper ?? this.paper,
      cloud: cloud ?? this.cloud,
      line: line ?? this.line,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      coin: coin ?? this.coin,
      seedGreen: seedGreen ?? this.seedGreen,
      sun: sun ?? this.sun,
      blossom: blossom ?? this.blossom,
      wood: wood ?? this.wood,
    );
  }

  @override
  MameroomTheme lerp(ThemeExtension<MameroomTheme>? other, double t) {
    if (other is! MameroomTheme) return this;
    return MameroomTheme(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryPressed: Color.lerp(primaryPressed, other.primaryPressed, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      primaryPale: Color.lerp(primaryPale, other.primaryPale, t)!,
      primaryMist: Color.lerp(primaryMist, other.primaryMist, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      cloud: Color.lerp(cloud, other.cloud, t)!,
      line: Color.lerp(line, other.line, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      coin: Color.lerp(coin, other.coin, t)!,
      seedGreen: Color.lerp(seedGreen, other.seedGreen, t)!,
      sun: Color.lerp(sun, other.sun, t)!,
      blossom: Color.lerp(blossom, other.blossom, t)!,
      wood: Color.lerp(wood, other.wood, t)!,
    );
  }
}

extension MameroomThemeLookup on BuildContext {
  MameroomTheme get mameroom {
    return Theme.of(this).extension<MameroomTheme>() ?? MameroomTheme.light;
  }
}
