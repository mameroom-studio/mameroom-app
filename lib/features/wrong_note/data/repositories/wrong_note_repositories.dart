import '../../domain/entities/wrong_note.dart';
import '../../domain/repositories/wrong_note_repository.dart';

final class ProductionWrongNoteRepository implements WrongNoteRepository {
  const ProductionWrongNoteRepository();
  @override
  Future<List<WrongNote>> loadWrongNotes() async => const [];
}

final class MockWrongNoteRepository implements WrongNoteRepository {
  const MockWrongNoteRepository({this.shouldFail = false});
  final bool shouldFail;
  @override
  Future<List<WrongNote>> loadWrongNotes() async {
    if (shouldFail) throw StateError('fixture failure');
    final now = DateTime.now();
    return List.generate(
      8,
      (index) => WrongNote(
        id: 'fixture-wrong-$index',
        questionText: index == 6
            ? '장기 부채와 자산의 현금흐름을 비교할 때 금리 민감도와 만기 구조를 함께 살펴야 하는 이유를 설명하세요. 매우 긴 제목에서도 카드의 텍스트가 화면 밖으로 넘치지 않아야 합니다.'
            : '복습 시 현재 기억률을 먼저 확인해야 하는 이유는 무엇인가요?',
        materialName: index.isEven ? '기억과 학습 전략' : '보험계리 핵심 개념',
        lastWrongAt: index == 0 ? now : now.subtract(Duration(days: index)),
        wrongCount: index == 1 ? 3 : index % 3 + 1,
        memoryRate: index == 4 ? .24 : .38 + index * .06,
        status: index == 2
            ? WrongNoteStatus.passed
            : index == 5
            ? WrongNoteStatus.reviewed
            : index == 1
            ? WrongNoteStatus.repeated
            : WrongNoteStatus.wrong,
        isBookmarked: index == 3,
        nextReviewAt: now.add(Duration(days: index + 1)),
        source: index == 7 ? null : '개발 전용 fixture 출처',
      ),
      growable: false,
    );
  }
}
