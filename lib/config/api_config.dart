class ApiConfig {
  /// Base URL for the backend API
  ///
  /// Development: Use your Mac's local IP address
  /// Example: 'http://192.168.1.100:8000'
  ///
  /// Production: Use your deployed backend URL
  /// Example: 'https://api.avafit.com'
  static const String baseUrl = 'http://192.168.10.19:8000';

  // Endpoint paths
  static const String generateAvatarPath = '/generate-avatar';
  static const String tryonPath = '/tryon';
  static const String garmentsPath = '/garments';

  // Full endpoint URLs
  static String get generateAvatarUrl => '$baseUrl$generateAvatarPath';
  static String get tryonUrl => '$baseUrl$tryonPath';
  static String get garmentsUrl => '$baseUrl$garmentsPath';

  /// Check if the API is configured
  static bool get isConfigured => !baseUrl.contains('YOUR_MAC_IP');

  /// ISSUE 2 FIX: Debug method to print API configuration
  static void debugPrint() {
    print('🔧 ========== API CONFIG ==========');
    print('🌐 API Base URL: $baseUrl');
    print('📍 Generate Avatar URL: $generateAvatarUrl');
    print('📍 Try-On URL: $tryonUrl');
    print('📍 Garments URL: $garmentsUrl');
    print('✅ Is Configured: $isConfigured');
    print('🔧 ==================================');
  }
}
