import 'package:flutter/material.dart';

class MameroomShadows {
  const MameroomShadows._();

  static const xs = [
    BoxShadow(color: Color(0x10000000), blurRadius: 4, offset: Offset(0, 2)),
  ];
  static const sm = [
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const md = [
    BoxShadow(color: Color(0x1A7B61FF), blurRadius: 20, offset: Offset(0, 8)),
  ];
  static const lg = [
    BoxShadow(color: Color(0x247B61FF), blurRadius: 32, offset: Offset(0, 16)),
  ];
  static const xl = [
    BoxShadow(color: Color(0x337B61FF), blurRadius: 48, offset: Offset(0, 24)),
  ];
}
