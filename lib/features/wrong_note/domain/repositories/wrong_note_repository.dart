import '../entities/wrong_note.dart';

abstract interface class WrongNoteRepository {
  Future<List<WrongNote>> loadWrongNotes();
}
