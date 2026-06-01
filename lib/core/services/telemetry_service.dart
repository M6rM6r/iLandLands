import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Telemetry event types
enum TelemetryEvent {
  cacheHit,
  cacheMiss,
  cacheSet,
  cacheRemove,
  cacheClear,
  cacheExpired,
  cacheError,
  syncSuccess,
  syncFailure,
  networkError,
}

/// Telemetry data point
class TelemetryData {

  const TelemetryData({
    required this.event,
    required this.data,
    required this.timestamp,
  });

  factory TelemetryData.fromJson(Map<String, dynamic> json) => TelemetryData(
    event: TelemetryEvent.values.firstWhere((e) => e.name == json['event'] as String),
    data: json['data'] as Map<String, dynamic>,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
  final TelemetryEvent event;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
    'event': event.name,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Cache performance metrics
class CachePerformanceMetrics {

  const CachePerformanceMetrics({
    required this.averageHitRate,
    required this.averageResponseTime,
    required this.totalRequests,
    required this.errorCount,
    required this.eventCounts,
  });
  final double averageHitRate;
  final Duration averageResponseTime;
  final int totalRequests;
  final int errorCount;
  final Map<String, int> eventCounts;
}

/// Telemetry service for monitoring cache and sync performance
class TelemetryService {

  TelemetryService(this._prefs);
  static const String _telemetryKey = 'cache_telemetry';
  static const String _metricsKey = 'cache_performance_metrics';
  static const int _maxEvents = 1000; // Keep last 1000 events

  final SharedPreferences _prefs;
  final StreamController<TelemetryData> _eventController = StreamController<TelemetryData>.broadcast();

  List<TelemetryData> _events = [];
  final Map<String, Stopwatch> _activeTimers = {};

  /// Initialize telemetry service
  static Future<TelemetryService> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final service = TelemetryService(prefs);
    await service._loadEvents();
    return service;
  }

  /// Stream of telemetry events
  Stream<TelemetryData> get events => _eventController.stream;

  /// Record a telemetry event
  void recordEvent(TelemetryEvent event, Map<String, dynamic> data) {
    final telemetryData = TelemetryData(
      event: event,
      data: data,
      timestamp: DateTime.now(),
    );

    _events.add(telemetryData);
    _eventController.add(telemetryData);

    // Keep only the last N events
    if (_events.length > _maxEvents) {
      _events = _events.sublist(_events.length - _maxEvents);
    }

    // Persist events
    _saveEvents();
  }

  /// Start timing an operation
  void startTimer(String operationId) {
    _activeTimers[operationId] = Stopwatch()..start();
  }

  /// End timing an operation and record the duration
  void endTimer(String operationId, {Map<String, dynamic>? additionalData}) {
    final stopwatch = _activeTimers.remove(operationId);
    if (stopwatch != null) {
      stopwatch.stop();
      final duration = stopwatch.elapsed;

      recordEvent(TelemetryEvent.cacheHit, {
        'operationId': operationId,
        'durationMs': duration.inMilliseconds,
        ...?additionalData,
      });
    }
  }

  /// Get cache performance metrics
  Future<CachePerformanceMetrics> getPerformanceMetrics() async {
    final eventCounts = <String, int>{};
    var totalRequests = 0;
    var errorCount = 0;
    var totalDurationMs = 0;
    var durationCount = 0;
    var totalHitRate = 0.0;
    var hitRateCount = 0;

    for (final event in _events) {
      final count = eventCounts[event.event.name] ?? 0;
      eventCounts[event.event.name] = count + 1;

      switch (event.event) {
        case TelemetryEvent.cacheHit:
        case TelemetryEvent.cacheMiss:
          totalRequests++;
          if (event.data['durationMs'] != null) {
            totalDurationMs += event.data['durationMs'] as int;
            durationCount++;
          }
        case TelemetryEvent.cacheError:
        case TelemetryEvent.syncFailure:
        case TelemetryEvent.networkError:
          errorCount++;
        default:
          break;
      }

      // Calculate hit rate from cache metrics
      if (event.data['hitRate'] != null) {
        totalHitRate += event.data['hitRate'] as double;
        hitRateCount++;
      }
    }

    final averageHitRate = hitRateCount > 0 ? totalHitRate / hitRateCount : 0.0;
    final averageResponseTime = durationCount > 0
        ? Duration(milliseconds: totalDurationMs ~/ durationCount)
        : Duration.zero;

    return CachePerformanceMetrics(
      averageHitRate: averageHitRate,
      averageResponseTime: averageResponseTime,
      totalRequests: totalRequests,
      errorCount: errorCount,
      eventCounts: eventCounts,
    );
  }

  /// Get events within a time range
  List<TelemetryData> getEventsInRange(DateTime start, DateTime end) {
    return _events.where((event) =>
        event.timestamp.isAfter(start) && event.timestamp.isBefore(end)).toList();
  }

  /// Clear all telemetry data
  Future<void> clear() async {
    _events.clear();
    _activeTimers.clear();
    await _prefs.remove(_telemetryKey);
    await _prefs.remove(_metricsKey);
  }

  /// Export telemetry data as JSON
  String exportData() {
    final data = {
      'events': _events.map((e) => e.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
    return json.encode(data);
  }

  /// Cache telemetry callback implementation
  void cacheTelemetryCallback(String event, Map<String, dynamic> data) {
    TelemetryEvent? telemetryEvent;

    switch (event) {
      case 'cache_hit':
        telemetryEvent = TelemetryEvent.cacheHit;
      case 'cache_miss':
      case 'cache_miss_file_not_found':
        telemetryEvent = TelemetryEvent.cacheMiss;
      case 'cache_set':
        telemetryEvent = TelemetryEvent.cacheSet;
      case 'cache_remove':
        telemetryEvent = TelemetryEvent.cacheRemove;
      case 'cache_clear':
        telemetryEvent = TelemetryEvent.cacheClear;
      case 'cache_expired':
        telemetryEvent = TelemetryEvent.cacheExpired;
      case 'cache_error':
      case 'cache_set_error':
      case 'cache_clear_error':
        telemetryEvent = TelemetryEvent.cacheError;
      default:
        return; // Unknown event
    }

    recordEvent(telemetryEvent, data);
  }

  /// Sync telemetry callback implementation
  void syncTelemetryCallback(String event, Map<String, dynamic> data) {
    TelemetryEvent? telemetryEvent;

    switch (event) {
      case 'sync_success':
        telemetryEvent = TelemetryEvent.syncSuccess;
      case 'sync_failure':
        telemetryEvent = TelemetryEvent.syncFailure;
      case 'network_error':
        telemetryEvent = TelemetryEvent.networkError;
      default:
        return;
    }

    recordEvent(telemetryEvent, data);
  }

  /// Load events from storage
  Future<void> _loadEvents() async {
    final eventsJson = _prefs.getString(_telemetryKey);
    if (eventsJson != null) {
      try {
        final data = json.decode(eventsJson) as List<dynamic>;
        _events = data.map((e) => TelemetryData.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        // Corrupted data, reset
        _events = [];
      }
    }
  }

  /// Save events to storage
  Future<void> _saveEvents() async {
    try {
      final data = _events.map((e) => e.toJson()).toList();
      await _prefs.setString(_telemetryKey, json.encode(data));
    } catch (e) {
      // If serialization fails, keep in memory only
    }
  }

  /// Dispose of resources
  void dispose() {
    _eventController.close();
  }
}

/// Combined telemetry hooks for cache and sync
class TelemetryHooks {

  TelemetryHooks(this._telemetry);
  final TelemetryService _telemetry;

  /// Cache telemetry callback
  void Function(String, Map<String, dynamic>) get cacheCallback =>
      _telemetry.cacheTelemetryCallback;

  /// Sync telemetry callback
  void Function(String, Map<String, dynamic>) get syncCallback =>
      _telemetry.syncTelemetryCallback;

  /// Get current performance metrics
  Future<CachePerformanceMetrics> getPerformanceMetrics() =>
      _telemetry.getPerformanceMetrics();

  /// Export telemetry data
  String exportData() => _telemetry.exportData();

  /// Clear telemetry data
  Future<void> clear() => _telemetry.clear();
}