class SupabaseBootstrap {
  const SupabaseBootstrap._();

  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static void markInitialized() {
    _isInitialized = true;
  }
}