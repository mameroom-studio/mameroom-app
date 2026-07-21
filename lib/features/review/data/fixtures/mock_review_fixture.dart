import '../../../quiz/domain/entities/question.dart';
import '../../domain/entities/review_schedule.dart';

abstract final class MockReviewFixture {
  static List<ReviewSchedule> dueReviews({DateTime? clock}) {
    final now = clock ?? DateTime.now();
    return List<ReviewSchedule>.generate(10, (index) {
      final shortAnswer = index == 4 || index == 8;
      return ReviewSchedule(
        id: 'fixture-review-$index',
        materialId: index.isEven
            ? 'fixture-material-memory'
            : 'fixture-material-actuary',
        conceptId: 'fixture-concept-$index',
        memoryStateId: 'fixture-memory-$index',
        scheduledAt: index == 0
            ? DateTime(now.year, now.month, now.day)
            : now.subtract(Duration(days: index == 1 ? 7 : index + 1)),
        memoryScore: index == 2 ? 0.22 : (0.38 + index * 0.045).clamp(0, 1),
        question: Question(
          id: 'fixture-question-$index',
          materialId: index.isEven
              ? 'fixture-material-memory'
              : 'fixture-material-actuary',
          conceptId: 'fixture-concept-$index',
          type: shortAnswer
              ? QuizQuestionType.shortAnswer
              : QuizQuestionType.multipleChoice,
          questionText: index == 9
              ? '장기 부채와 자산의 현금흐름을 함께 검토할 때 금리 변동, 만기 구조, 유동성 위험을 종합하여 가장 먼저 확인해야 하는 항목은 무엇인가요?'
              : '기억을 오래 유지하기 위해 복습 시점에 가장 먼저 확인할 항목은 무엇인가요?',
          options: shortAnswer
              ? const []
              : index == 9
              ? const [
                  '장기 부채와 자산의 현금흐름, 만기 구조 및 금리 민감도를 함께 비교한다',
                  '최근 한 달의 마케팅 비용만 단독으로 확인한다',
                  '브랜드 색상 가이드와 문서 서식을 우선 검토한다',
                  '고객 메모의 글자 수만 집계한다',
                ]
              : const ['현재 기억률', '앱 아이콘', '프로필 색상', '방 꾸미기'],
          answer: shortAnswer
              ? '현재 기억률'
              : index == 9
              ? '장기 부채와 자산의 현금흐름, 만기 구조 및 금리 민감도를 함께 비교한다'
              : '현재 기억률',
          explanation: '현재 기억 상태와 복습 이유를 확인하면 적절한 회상 전략을 선택할 수 있습니다.',
          evidence: index == 7 ? '' : '개발 전용 fixture 출처 · p.${index + 2}',
          difficulty: index % 4 + 1,
          orderIndex: index,
          sectionId: index == 7 ? null : '개발 전용 fixture 섹션',
        ),
      );
    }, growable: false);
  }
}
