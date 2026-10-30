class AppConstants {
  AppConstants._();

  static const String appName = 'LMS Ngoại Ngữ';
  static const String appVersion = '1.0.0';

  // Secure Storage Keys
  static const String keyAccessToken = 'lms_access_token';
  static const String keyRefreshToken = 'lms_refresh_token';
  static const String keyUserData = 'lms_user_data';
  static const String keySavedIdentifier = 'lms_saved_identifier';
  static const String keyThemeMode = 'lms_theme_mode';

  // Network Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);
}
