import 'package:flutter/material.dart';

@immutable
class MameroomTheme extends ThemeExtension<MameroomTheme> {
  const MameroomTheme({
    required this.primary,
    required this.primarySoft,
    required this.primaryPale,
    required this.primaryMist,
    required this.paper,
    required this.cloud,
    required this.line,
    required this.ink,
    required this.muted,
    required this.seedGreen,
    required this.sun,
    required this.blossom,
    required this.wood,
  });

  final Color primary;
  final Color primarySoft;
  final Color primaryPale;
  final Color primaryMist;
  final Color paper;
  final Color cloud;
  final Color line;
  final Color ink;
  final Color muted;
  final Color seedGreen;
  final Color sun;
  final Color blossom;
  final Color wood;

  static const light = MameroomTheme(
    primary: Color(0xFF7C5CFF),
    primarySoft: Color(0xFFA780FA),
    primaryPale: Color(0xFFC4B5FD),
    primaryMist: Color(0xFFDDD6FE),
    paper: Color(0xFFFFFFFF),
    cloud: Color(0xFFF7F7FF),
    line: Color(0xFFECE9F7),
    ink: Color(0xFF16115A),
    muted: Color(0xFF74709B),
    seedGreen: Color(0xFF8ECF7A),
    sun: Color(0xFFFFD76B),
    blossom: Color(0xFFFB70A5),
    wood: Color(0xFFC89A67),
  );

  @override
  MameroomTheme copyWith({
    Color? primary,
    Color? primarySoft,
    Color? primaryPale,
    Color? primaryMist,
    Color? paper,
    Color? cloud,
    Color? line,
    Color? ink,
    Color? muted,
    Color? seedGreen,
    Color? sun,
    Color? blossom,
    Color? wood,
  }) {
    return MameroomTheme(
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      primaryPale: primaryPale ?? this.primaryPale,
      primaryMist: primaryMist ?? this.primaryMist,
      paper: paper ?? this.paper,
      cloud: cloud ?? this.cloud,
      line: line ?? this.line,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      seedGreen: seedGreen ?? this.seedGreen,
      sun: sun ?? this.sun,
      blossom: blossom ?? this.blossom,
      wood: wood ?? this.wood,
    );
  }

  @override
  MameroomTheme lerp(ThemeExtension<MameroomTheme>? other, double t) {
    if (other is! MameroomTheme) {
      return this;
    }

    return MameroomTheme(
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      primaryPale: Color.lerp(primaryPale, other.primaryPale, t)!,
      primaryMist: Color.lerp(primaryMist, other.primaryMist, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      cloud: Color.lerp(cloud, other.cloud, t)!,
      line: Color.lerp(line, other.line, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
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
