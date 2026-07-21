enum FriendsFailureKind {
  validation,
  authentication,
  authorization,
  conflict,
  network,
  timeout,
  schema,
  server,
  parsing,
  unknown,
}

final class FriendsFailure implements Exception {
  const FriendsFailure(this.kind, this.message, {this.operation});

  final FriendsFailureKind kind;
  final String message;
  final String? operation;
}
