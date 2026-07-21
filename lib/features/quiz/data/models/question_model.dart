import '../../domain/entities/question.dart';

class QuestionModel extends Question {
  const QuestionModel({
    required super.id,
    required super.materialId,
    required super.conceptId,
    required super.type,
    required super.questionText,
    required super.options,
    required super.answer,
    required super.explanation,
    required super.evidence,
    required super.difficulty,
    required super.orderIndex,
    super.sectionId,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      materialId: json['material_id'] as String,
      conceptId: json['concept_id'] as String,
      sectionId: json['section_id'] as String?,
      type: QuizQuestionType.fromValue(json['type'] as String? ?? ''),
      questionText: json['question_text'] as String? ?? '',
      options: _optionsFrom(json['options']),
      answer: json['answer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      evidence: _evidenceFrom(json['evidence']),
      difficulty: json['difficulty'] as int? ?? 3,
      orderIndex: json['order_index'] as int? ?? 0,
    );
  }

  static List<String> _optionsFrom(Object? value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    return const [];
  }

  static String _evidenceFrom(Object? value) {
    if (value is Map) {
      final text = value['text'];
      if (text != null) {
        return text.toString();
      }
    }
    return value?.toString() ?? '';
  }
}
