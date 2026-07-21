import 'package:flutter/material.dart';

class MameroomRadius {
  const MameroomRadius._();

  static const double r4 = 4;
  static const double r8 = 8;
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r32 = 32;
  static const double full = 999;

  static const small = r8;
  static const medium = r12;
  static const large = r16;
  static const card = r20;
  static const modal = r32;
  static const pill = full;

  static BorderRadius get smallRadius => BorderRadius.circular(small);
  static BorderRadius get mediumRadius => BorderRadius.circular(medium);
  static BorderRadius get cardRadius => BorderRadius.circular(card);
  static BorderRadius get pillRadius => BorderRadius.circular(pill);
}
