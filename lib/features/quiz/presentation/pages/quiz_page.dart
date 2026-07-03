import 'package:flutter/material.dart';

import '../../../study/presentation/pages/study_screen.dart';

class QuizPage extends StatelessWidget {
  const QuizPage({required this.materialId, super.key});

  static const routePath = '/quiz';

  final String? materialId;

  @override
  Widget build(BuildContext context) {
    return StudyScreen(materialId: materialId);
  }
}
