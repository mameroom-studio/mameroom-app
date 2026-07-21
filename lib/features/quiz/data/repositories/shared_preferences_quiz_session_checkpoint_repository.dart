import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/quiz_session_checkpoint.dart';
import '../../domain/repositories/quiz_session_checkpoint_repository.dart';
import '../models/quiz_session_checkpoint_model.dart';

class SharedPreferencesQuizSessionCheckpointRepository
    implements QuizSessionCheckpointRepository {
  SharedPreferencesQuizSessionCheckpointRepository({
    required this.userId,
    Future<SharedPreferences> Function()? preferencesFactory,
  }) : _preferencesFactory =
           preferencesFactory ?? SharedPreferences.getInstance;

  static const _keyPrefix = 'quiz_session_checkpoint:v1:';

  final String userId;
  final Future<SharedPreferences> Function() _preferencesFactory;

  String get _key => '$_keyPrefix$userId';

  @override
  Future<QuizSessionCheckpoint?> loadLatest() async {
    final preferences = await _preferencesFactory();
    final encoded = preferences.getString(_key);
    if (encoded == null || encoded.isEmpty) return null;

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        await preferences.remove(_key);
        return null;
      }
      final model = QuizSessionCheckpointModel.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (model.materialId.isEmpty || model.questionIds.isEmpty) {
        await preferences.remove(_key);
        return null;
      }
      return model.toEntity();
    } on FormatException {
      await preferences.remove(_key);
      return null;
    } on TypeError {
      await preferences.remove(_key);
      return null;
    }
  }

  @override
  Future<void> save(QuizSessionCheckpoint checkpoint) async {
    final preferences = await _preferencesFactory();
    final model = QuizSessionCheckpointModel.fromEntity(checkpoint);
    await preferences.setString(_key, jsonEncode(model.toJson()));
  }

  @override
  Future<void> clear() async {
    final preferences = await _preferencesFactory();
    await preferences.remove(_key);
  }
}
