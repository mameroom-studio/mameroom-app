import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/env.dart';
import '../../data/repositories/wrong_note_repositories.dart';
import '../../domain/entities/wrong_note.dart';
import '../../domain/repositories/wrong_note_repository.dart';

final wrongNoteRepositoryProvider = Provider<WrongNoteRepository>(
  (ref) => Env.useMockReview
      ? const MockWrongNoteRepository()
      : const ProductionWrongNoteRepository(),
);
final wrongNotesProvider = FutureProvider<List<WrongNote>>(
  (ref) => ref.watch(wrongNoteRepositoryProvider).loadWrongNotes(),
);
