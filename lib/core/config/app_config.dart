/// Centralized configuration for the Gulf Lands application.
/// Provides static access to various constants, ensuring consistency and easy modification.
class AppConfig {
  // General App Info
  static const String appName = 'Gulf Lands Market';
  static const String appVersion = '2.0.0';
  static const String buildNumber = '1';

  // API Keys & Endpoints
  // IMPORTANT: For production, these should be loaded securely (e.g., environment variables, Firebase Remote Config)
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  static const String analyticsApiBaseUrl =
      'https://api.gulflands.com/analytics/v1';
  static const String mainApiBaseUrl = 'https://api.gulflands.com/v1';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double cardRadius = 12.0;
  static const double imageHeight = 200.0;

  // Animation Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  // Analytics Event Names (for consistency with Python backend)
  static const String eventAppOpened = 'app_opened';
  static const String eventSearchPerformed = 'search_performed';
  static const String eventFilterApplied = 'filter_applied';
  static const String eventListingViewed = 'listing_viewed';
  static const String eventFavoriteAdded = 'favorite_added';
  static const String eventFavoriteRemoved = 'favorite_removed';
  static const String eventContactRequested = 'contact_requested';

  // Analytics Property Names
  static const String propertyAppVersion = 'app_version';
  static const String propertyBuildNumber = 'build_number';
  static const String propertyDeviceType = 'device_type';
  static const String propertyConnectionType = 'connection_type';
  static const String propertyCountry = 'country';
}
