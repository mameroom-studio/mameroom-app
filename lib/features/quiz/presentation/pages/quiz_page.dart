import 'package:flutter/material.dart';

import '../../../study/presentation/pages/study_screen.dart';

class QuizPage extends StatelessWidget {
  const QuizPage({
    required this.materialId,
    this.unlearnedOnly = false,
    super.key,
  });

  static const routePath = '/quiz';

  final String? materialId;
  final bool unlearnedOnly;

  static String location(String materialId, {bool unlearnedOnly = false}) {
    final suffix = unlearnedOnly ? '&unlearnedOnly=true' : '';
    return '$routePath?materialId=$materialId$suffix';
  }

  @override
  Widget build(BuildContext context) {
    return StudyScreen(materialId: materialId, unlearnedOnly: unlearnedOnly);
  }
}
