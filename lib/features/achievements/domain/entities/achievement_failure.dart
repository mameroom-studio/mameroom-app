enum AchievementFailureKind {
  authentication,
  authorization,
  network,
  timeout,
  schema,
  parsing,
  notFound,
  server,
  unknown,
}

class AchievementFailure implements Exception {
  const AchievementFailure(
    this.kind,
    this.userMessage, {
    required this.operation,
  });

  final AchievementFailureKind kind;
  final String userMessage;
  final String operation;

  @override
  String toString() => 'AchievementFailure($kind, operation: $operation)';
}

class AchievementNotFoundException implements Exception {
  const AchievementNotFoundException();

  @override
  String toString() => 'AchievementNotFoundException';
}
