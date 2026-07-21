enum ProfileFailureKind {
  authentication,
  notFound,
  authorization,
  network,
  timeout,
  schema,
  server,
  parsing,
  conflict,
  validation,
  unknown,
}

class ProfileFailure implements Exception {
  const ProfileFailure(this.kind, this.userMessage, {required this.operation});

  final ProfileFailureKind kind;
  final String userMessage;
  final String operation;

  @override
  String toString() => 'ProfileFailure($kind, operation: $operation)';
}

class ProfileNotFoundException implements Exception {
  const ProfileNotFoundException();

  @override
  String toString() => 'ProfileNotFoundException';
}
