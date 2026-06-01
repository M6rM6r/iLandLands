import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'Gulf Lands Market';
  static const String appVersion = '2.0.0';
  static const String buildNumber = '1';
  
  // API Configuration
  static const String baseUrl = kDebugMode 
      ? 'http://localhost:80/api/v1' 
      : 'https://api.gulflands.com/v1';
  
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 25);
  
  // Cache Configuration
  static const Duration cacheDuration = Duration(hours: 1);
  static const Duration imageCacheDuration = Duration(days: 7);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Analytics
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = !kDebugMode;
  static const bool enablePerformanceMonitoring = !kDebugMode;
  
  // Feature Flags
  static const bool enableAdvancedSearch = true;
  static const bool enableFavorites = true;
  static const bool enableLocationServices = true;
  static const bool enableImageUpload = true;
  static const bool enablePushNotifications = true;
  static const bool enableBiometricAuth = true;
  static const bool enableDarkMode = true;
  static const bool enableOfflineMode = true;
  
  // UI Configuration
  static const double defaultPadding = 16;
  static const double cardRadius = 12;
  static const double buttonRadius = 8;
  static const double imageHeight = 200;
  
  // Animation Configuration
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 600);
  
  // Validation Rules
  static const int minSearchLength = 2;
  static const int maxSearchLength = 100;
  static const int maxTitleLength = 255;
  static const int maxDescriptionLength = 1000;
  static const double minPrice = 0;
  static const double maxPrice = 999999999.99;
  static const double minArea = 1;
  static const double maxArea = 1000000;
  
  // Error Handling
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 1);
  
  // Security
  static const bool enableSSL = true;
  static const bool enableCertificatePinning = !kDebugMode;
  static const Duration sessionTimeout = Duration(hours: 24);
  
  // Performance
  static const int maxConcurrentRequests = 10;
  static const bool enableImageCompression = true;
  static const double imageQuality = 0.8;
  
  // Logging
  static const bool enableLogging = kDebugMode;
  static const int maxLogFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxLogFiles = 5;
  
  // Storage Keys
  static const String userPreferencesKey = 'user_preferences';
  static const String favoritesKey = 'favorites';
  static const String searchHistoryKey = 'search_history';
  static const String sessionKey = 'session_data';
  static const String themeKey = 'theme_settings';
  static const String languageKey = 'language_settings';
  
  // Deep Links
  static const String scheme = 'gulflands';
  static const String host = 'gulflands.com';
  
  // Social Sharing
  static const String shareUrl = 'https://gulflands.com';
  static const String supportEmail = 'support@gulflands.com';
  static const String phoneNumber = '+966500000000';
  
  // Rate Limiting
  static const int maxSearchRequestsPerMinute = 30;
  static const int maxApiRequestsPerMinute = 100;
  static const int maxImageUploadsPerHour = 10;
  
  // Content Moderation
  static const List<String> bannedWords = [
    // Add inappropriate words for content filtering
  ];
  
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  
  // Notification Configuration
  static const Duration notificationCooldown = Duration(minutes: 5);
  static const int maxNotificationsPerDay = 50;
  
  // Map Configuration
  static const double defaultMapZoom = 10;
  static const double minMapZoom = 3;
  static const double maxMapZoom = 18;
  
  // Analytics Events
  static const String eventListingViewed = 'listing_viewed';
  static const String eventSearchPerformed = 'search_performed';
  static const String eventFilterApplied = 'filter_applied';
  static const String eventFavoriteAdded = 'favorite_added';
  static const String eventFavoriteRemoved = 'favorite_removed';
  static const String eventContactRequested = 'contact_requested';
  static const String eventImageUploaded = 'image_uploaded';
  static const String eventLocationAccessed = 'location_accessed';
  static const String eventPushNotificationReceived = 'push_notification_received';
  static const String eventAppOpened = 'app_opened';
  static const String eventAppBackgrounded = 'app_backgrounded';
  static const String eventErrorOccurred = 'error_occurred';
  
  // Custom Properties for Analytics
  static const String propertyCountry = 'country';
  static const String propertyPriceRange = 'price_range';
  static const String propertyAreaRange = 'area_range';
  static const String propertyListingType = 'listing_type';
  static const String propertyUserType = 'user_type';
  static const String propertyDeviceType = 'device_type';
  static const String propertyConnectionType = 'connection_type';
  static const String propertyAppVersion = 'app_version';
  static const String propertyBuildNumber = 'build_number';
  
  // A/B Testing
  static const bool enableABTesting = true;
  static const String abTestGroupKey = 'ab_test_group';
  static const Map<String, dynamic> abTestConfig = {
    'new_search_ui': 0.5,
    'enhanced_filters': 0.3,
    'ai_recommendations': 0.2,
  };
  
  // Feature Toggles
  static const Map<String, bool> featureToggles = {
    'ai_search': false,
    'virtual_tours': false,
    'blockchain_verification': false,
    'ar_viewing': false,
    'voice_search': false,
    'smart_recommendations': false,
  };
  
  // Development Settings
  static const bool enableDebugMenu = kDebugMode;
  static const bool enableNetworkInspector = kDebugMode;
  static const bool enablePerformanceOverlay = kDebugMode;
  static const bool enableWidgetInspector = kDebugMode;
}
