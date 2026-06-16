import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:gulflands/core/config/app_config.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AnalyticsService {
  Future<void> trackEvent(String name, {Map<String, dynamic>? parameters});
  Future<void> trackScreenView(
    String screenName, {
    Map<String, dynamic>? parameters,
  });
  Future<void> trackUserProperty(String name, String value);
  Future<void> setUserId(String userId);
  Future<void> trackError(Exception error, {StackTrace? stackTrace});
  Future<void> trackPerformance(String operation, Duration duration);
  Future<void> trackSearch(String query, int resultsCount);
  Future<void> trackFilter(Map<String, dynamic> filters);
  Future<void> trackListingView(
    String listingId,
    Map<String, dynamic> listingData,
  );
  Future<void> trackFavorite(String listingId, bool added);
  Future<void> trackContact(String listingId, String method);
  Future<void> trackAppLifecycle(String state);
  Future<void> trackNetworkRequest(
    String url,
    int statusCode,
    Duration duration,
  );
  Future<void> trackUserEngagement(String feature, Duration duration);
  Future<void> trackConversion(String type, Map<String, dynamic> data);
  Future<void> trackRetention(String cohort, Duration sessionDuration);
  Future<void> trackMonetization(String event, double value, String currency);
  Future<void> trackCustomEvent(String name, Map<String, dynamic> parameters);
  Future<Map<String, dynamic>> getAnalyticsData();
  Future<void> flush();
}

class AnalyticsServiceImpl implements AnalyticsService {
  AnalyticsServiceImpl(this.logger, this.sharedPreferences) {
    _firebaseAnalytics = FirebaseAnalytics.instance;
    _crashlytics = FirebaseCrashlytics.instance;
    _initializeAnalytics();
  }
  final Logger logger;
  final SharedPreferences sharedPreferences;
  late final FirebaseAnalytics _firebaseAnalytics;
  late final FirebaseCrashlytics _crashlytics;

  String? _userId;
  final Map<String, String> _userProperties = <String, String>{};
  final Map<String, dynamic> _sessionData = <String, dynamic>{};
  DateTime? _sessionStart;
  final List<Map<String, dynamic>> _eventQueue = <Map<String, dynamic>>[];

  Future<void> _initializeAnalytics() async {
    try {
      await _setUserProperties();
      await _trackAppOpen();
      _sessionStart = DateTime.now();

      // Set default parameters
      await _firebaseAnalytics.setDefaultEventParameters(<String, Object?>{
        AppConfig.propertyAppVersion: AppConfig.appVersion,
        AppConfig.propertyBuildNumber: AppConfig.buildNumber,
        AppConfig.propertyDeviceType: await _getDeviceType(),
        AppConfig.propertyConnectionType: await _getConnectionType(),
      });

      logger.d('Analytics service initialized');
    } catch (e) {
      logger.e('Failed to initialize analytics: $e');
    }
  }

  @override
  Future<void> trackEvent(
    String name, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final Map<String, dynamic> enrichedParameters = await _enrichParameters(
        parameters,
      );

      // Track in Firebase Analytics
      await _firebaseAnalytics.logEvent(
        name: name,
        parameters: enrichedParameters.cast<String, Object>(),
      );

      // Add to local queue for batch processing
      _eventQueue.add(<String, dynamic>{
        'name': name,
        'parameters': enrichedParameters,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Track in local analytics
      await _trackLocalEvent(name, enrichedParameters);

      logger.d('Event tracked: $name');
    } catch (e) {
      logger.e('Failed to track event: $e');
    }
  }

  @override
  Future<void> trackScreenView(
    String screenName, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final Map<String, dynamic> enrichedParameters = await _enrichParameters(
        parameters,
      );

      await _firebaseAnalytics.logScreenView(
        screenName: screenName,
        parameters: enrichedParameters.cast<String, Object>(),
      );

      await _trackLocalEvent('screen_view', <String, dynamic>{
        'screen_name': screenName,
        ...enrichedParameters,
      });

      logger.d('Screen view tracked: $screenName');
    } catch (e) {
      logger.e('Failed to track screen view: $e');
    }
  }

  @override
  Future<void> trackUserProperty(String name, String value) async {
    try {
      await _firebaseAnalytics.setUserProperty(name: name, value: value);
      _userProperties[name] = value;

      await sharedPreferences.setString('user_property_$name', value);

      logger.d('User property tracked: $name = $value');
    } catch (e) {
      logger.e('Failed to track user property: $e');
    }
  }

  @override
  Future<void> setUserId(String userId) async {
    try {
      await _firebaseAnalytics.setUserId(id: userId);
      await _crashlytics.setUserIdentifier(userId);
      _userId = userId;

      await sharedPreferences.setString('user_id', userId);

      logger.d('User ID set: $userId');
    } catch (e) {
      logger.e('Failed to set user ID: $e');
    }
  }

  @override
  Future<void> trackError(Exception error, {StackTrace? stackTrace}) async {
    try {
      await _crashlytics.recordError(error, stackTrace);

      await _trackLocalEvent('error', <String, dynamic>{
        'error_type': error.runtimeType.toString(),
        'error_message': error.toString(),
        'stack_trace': stackTrace?.toString(),
      });

      logger.e('Error tracked: $error');
    } catch (e) {
      logger.e('Failed to track error: $e');
    }
  }

  @override
  Future<void> trackPerformance(String operation, Duration duration) async {
    try {
      await _trackLocalEvent('performance', <String, dynamic>{
        'operation': operation,
        'duration_ms': duration.inMilliseconds,
      });

      logger.d(
        'Performance tracked: $operation took ${duration.inMilliseconds}ms',
      );
    } catch (e) {
      logger.e('Failed to track performance: $e');
    }
  }

  @override
  Future<void> trackSearch(String query, int resultsCount) async {
    await trackEvent(
      AppConfig.eventSearchPerformed,
      parameters: <String, dynamic>{
        'query': query,
        'results_count': resultsCount,
        'query_length': query.length,
      },
    );
  }

  @override
  Future<void> trackFilter(Map<String, dynamic> filters) async {
    await trackEvent(
      AppConfig.eventFilterApplied,
      parameters: <String, dynamic>{
        'filters_applied': filters.keys.length,
        'filter_types': filters.keys.toList(),
      },
    );
  }

  @override
  Future<void> trackListingView(
    String listingId,
    Map<String, dynamic> listingData,
  ) async {
    await trackEvent(
      AppConfig.eventListingViewed,
      parameters: <String, dynamic>{
        'listing_id': listingId,
        AppConfig.propertyCountry: listingData['country'],
        'price_range': _getPriceRange(
          (listingData['price'] as num?)?.toDouble() ?? 0.0,
        ),
        'area_range': _getAreaRange(
          (listingData['area'] as num?)?.toDouble() ?? 0.0,
        ),
        'is_featured': listingData['is_featured'] ?? false,
      },
    );
  }

  @override
  Future<void> trackFavorite(String listingId, bool added) async {
    await trackEvent(
      added ? AppConfig.eventFavoriteAdded : AppConfig.eventFavoriteRemoved,
      parameters: <String, dynamic>{'listing_id': listingId},
    );
  }

  @override
  Future<void> trackContact(String listingId, String method) async {
    await trackEvent(
      AppConfig.eventContactRequested,
      parameters: <String, dynamic>{
        'listing_id': listingId,
        'contact_method': method,
      },
    );
  }

  @override
  Future<void> trackAppLifecycle(String state) async {
    await trackEvent(
      'app_lifecycle',
      parameters: <String, dynamic>{'state': state},
    );

    if (state == 'background' && _sessionStart != null) {
      final Duration sessionDuration = DateTime.now().difference(
        _sessionStart!,
      );
      await trackRetention('daily', sessionDuration);
    } else if (state == 'resumed') {
      _sessionStart = DateTime.now();
    }
  }

  @override
  Future<void> trackNetworkRequest(
    String url,
    int statusCode,
    Duration duration,
  ) async {
    await trackEvent(
      'network_request',
      parameters: <String, dynamic>{
        'url': url,
        'status_code': statusCode,
        'duration_ms': duration.inMilliseconds,
        'success': statusCode >= 200 && statusCode < 300,
      },
    );
  }

  @override
  Future<void> trackUserEngagement(String feature, Duration duration) async {
    await trackEvent(
      'user_engagement',
      parameters: <String, dynamic>{
        'feature': feature,
        'duration_ms': duration.inMilliseconds,
      },
    );
  }

  @override
  Future<void> trackConversion(String type, Map<String, dynamic> data) async {
    await trackEvent(
      'conversion',
      parameters: <String, dynamic>{'conversion_type': type, ...data},
    );
  }

  @override
  Future<void> trackRetention(String cohort, Duration sessionDuration) async {
    await trackEvent(
      'retention',
      parameters: <String, dynamic>{
        'cohort': cohort,
        'session_duration_ms': sessionDuration.inMilliseconds,
      },
    );
  }

  @override
  Future<void> trackMonetization(
    String event,
    double value,
    String currency,
  ) async {
    await trackEvent(
      'monetization',
      parameters: <String, dynamic>{
        'event': event,
        'value': value,
        'currency': currency,
      },
    );
  }

  @override
  Future<void> trackCustomEvent(
    String name,
    Map<String, dynamic> parameters,
  ) async {
    await trackEvent(name, parameters: parameters);
  }

  @override
  Future<Map<String, dynamic>> getAnalyticsData() async {
    try {
      return <String, dynamic>{
        'user_id': _userId,
        'user_properties': _userProperties,
        'session_data': _sessionData,
        'event_queue': _eventQueue,
        'session_start': _sessionStart?.toIso8601String(),
      };
    } catch (e) {
      logger.e('Failed to get analytics data: $e');
      return <String, dynamic>{};
    }
  }

  @override
  Future<void> flush() async {
    try {
      // Process event queue
      for (final Map<String, dynamic> event in _eventQueue) {
        await _processEvent(event);
      }
      _eventQueue.clear();

      logger.d('Analytics flushed');
    } catch (e) {
      logger.e('Failed to flush analytics: $e');
    }
  }

  Future<Map<String, dynamic>> _enrichParameters(
    Map<String, dynamic>? parameters,
  ) async {
    final Map<String, dynamic> enriched = Map<String, dynamic>.from(
      parameters ?? <dynamic, dynamic>{},
    );

    enriched['timestamp'] = DateTime.now().toIso8601String();
    enriched['user_id'] = _userId;
    enriched['session_id'] = await _getSessionId();

    return enriched;
  }

  Future<void> _trackLocalEvent(
    String name,
    Map<String, dynamic> parameters,
  ) async {
    final List<String> events =
        sharedPreferences.getStringList('local_events') ?? <String>[];
    events.add('$name:$parameters:${DateTime.now().toIso8601String()}');

    // Keep only last 1000 events
    if (events.length > 1000) {
      events.removeRange(0, events.length - 1000);
    }

    await sharedPreferences.setStringList('local_events', events);
  }

  Future<void> _processEvent(Map<String, dynamic> event) async {
    // Process event for local analytics
    logger.d('Processing event: ${event['name']}');
  }

  Future<void> _setUserProperties() async {
    final Iterable<String> keys = sharedPreferences.getKeys().where(
      (String key) => key.startsWith('user_property_'),
    );

    for (final String key in keys) {
      final String? value = sharedPreferences.getString(key);
      if (value != null) {
        final String propertyName = key.replaceFirst('user_property_', '');
        _userProperties[propertyName] = value;
        await _firebaseAnalytics.setUserProperty(
          name: propertyName,
          value: value,
        );
      }
    }
  }

  Future<void> _trackAppOpen() async {
    await trackEvent(AppConfig.eventAppOpened);

    final String? lastOpen = sharedPreferences.getString('last_open');
    if (lastOpen != null) {
      final DateTime lastOpenDate = DateTime.parse(lastOpen);
      final int daysSinceLastOpen = DateTime.now()
          .difference(lastOpenDate)
          .inDays;

      await trackEvent(
        'app_return',
        parameters: <String, dynamic>{
          'days_since_last_open': daysSinceLastOpen,
        },
      );
    }

    await sharedPreferences.setString(
      'last_open',
      DateTime.now().toIso8601String(),
    );
  }

  Future<String> _getSessionId() async {
    String? sessionId = sharedPreferences.getString('session_id');

    if (sessionId == null) {
      sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
      await sharedPreferences.setString('session_id', sessionId);
    }

    return sessionId;
  }

  Future<String> _getDeviceType() async {
    if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await DeviceInfoPlugin().iosInfo;
      return 'ios_${iosInfo.model}';
    } else if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo =
          await DeviceInfoPlugin().androidInfo;
      return 'android_${androidInfo.model}';
    } else if (kIsWeb) {
      return 'web';
    } else {
      return 'unknown';
    }
  }

  Future<String> _getConnectionType() async {
    // This would require connectivity_plus integration
    return 'unknown';
  }

  String _getPriceRange(double price) {
    if (price < 1000000) return 'under_1m';
    if (price < 5000000) return '1m_to_5m';
    if (price < 10000000) return '5m_to_10m';
    return 'over_10m';
  }

  String _getAreaRange(double area) {
    if (area < 1000) return 'under_1k';
    if (area < 10000) return '1k_to_10k';
    if (area < 50000) return '10k_to_50k';
    return 'over_50k';
  }
}
