import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache entry metadata stored in SharedPreferences
class CacheEntry { // Whether this entry is stale but still valid

  const CacheEntry({
    required this.key,
    required this.createdAt,
    required this.size,
    required this.filePath,
    this.expiresAt,
    this.isStale = false,
  });

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
    key: json['key'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
    size: json['size'] as int,
    filePath: json['filePath'] as String,
    isStale: (json['isStale'] as bool?) ?? false,
  );
  final String key;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int size; // Size in bytes
  final String filePath; // Path to the JSON file
  final bool isStale;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Map<String, dynamic> toJson() => {
    'key': key,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt?.toIso8601String(),
    'size': size,
    'filePath': filePath,
    'isStale': isStale,
  };
}

/// Cache health metrics for monitoring
class CacheMetrics {

  const CacheMetrics({
    required this.totalEntries,
    required this.staleEntries,
    required this.expiredEntries,
    required this.totalSize,
    required this.hitRate,
    required this.missCount,
    required this.hitCount,
  });
  final int totalEntries;
  final int staleEntries;
  final int expiredEntries;
  final int totalSize; // Total size in bytes
  final double hitRate; // Percentage of cache hits
  final int missCount;
  final int hitCount;

  Map<String, dynamic> toJson() => {
    'totalEntries': totalEntries,
    'staleEntries': staleEntries,
    'expiredEntries': expiredEntries,
    'totalSize': totalSize,
    'hitRate': hitRate,
    'missCount': missCount,
    'hitCount': hitCount,
  };
}

/// Telemetry callback for cache events
typedef CacheTelemetryCallback = void Function(String event, Map<String, dynamic> data);

/// Offline-first cache repository with TTL-based invalidation and stale-while-revalidate
class CacheRepository {

  CacheRepository(this._prefs, {CacheTelemetryCallback? telemetryCallback})
      : _telemetryCallback = telemetryCallback;
  static const String _metadataKey = 'cache_metadata';
  static const String _metricsKey = 'cache_metrics';
  static const String _cacheDir = 'gulflands_cache';

  final SharedPreferences _prefs;
  final CacheTelemetryCallback? _telemetryCallback;

  // Metrics tracking
  int _hitCount = 0;
  int _missCount = 0;

  /// Initialize the cache repository
  static Future<CacheRepository> initialize({CacheTelemetryCallback? telemetryCallback}) async {
    final prefs = await SharedPreferences.getInstance();
    final repo = CacheRepository(prefs, telemetryCallback: telemetryCallback);
    await repo._loadMetrics();
    return repo;
  }

  /// Get cached data with stale-while-revalidate behavior
  Future<T?> get<T>(String key) async {
    try {
      final metadata = await _getMetadata();
      final entry = metadata[key];

      if (entry == null) {
        _missCount++;
        _telemetryCallback?.call('cache_miss', {'key': key});
        return null;
      }

      // Check if file exists
      final file = File(entry.filePath);
      if (!await file.exists()) {
        await _removeEntry(key);
        _missCount++;
        _telemetryCallback?.call('cache_miss_file_not_found', {'key': key});
        return null;
      }

      // Check expiration
      if (entry.isExpired) {
        // Mark as stale but still return if possible - create new entry with isStale=true
        final staleEntry = CacheEntry(
          key: entry.key,
          createdAt: entry.createdAt,
          size: entry.size,
          filePath: entry.filePath,
          expiresAt: entry.expiresAt,
          isStale: true,
        );
        await _updateMetadataEntry(key, staleEntry);
        _telemetryCallback?.call('cache_expired', {'key': key, 'age': DateTime.now().difference(entry.createdAt).inMinutes});
      }

      // Read and parse the JSON file
      final content = await file.readAsString();
      final data = json.decode(content);

      _hitCount++;
      _telemetryCallback?.call('cache_hit', {
        'key': key,
        'isStale': entry.isStale,
        'age': DateTime.now().difference(entry.createdAt).inMinutes,
        'size': entry.size,
      });

      return data as T;
    } catch (e) {
      _missCount++;
      _telemetryCallback?.call('cache_error', {'key': key, 'error': e.toString()});
      // Try to clean up corrupted entry
      await _removeEntry(key);
      return null;
    }
  }

  /// Store data in cache with optional TTL
  Future<void> set<T>(String key, T data, {Duration? ttl}) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final fileName = '${key.hashCode}.json';
      final filePath = path.join(cacheDir.path, fileName);

      // Serialize data to JSON
      final jsonData = json.encode(data);
      final file = File(filePath);

      // Write to file
      await file.writeAsString(jsonData);

      // Create metadata entry
      final entry = CacheEntry(
        key: key,
        createdAt: DateTime.now(),
        expiresAt: ttl != null ? DateTime.now().add(ttl) : null,
        size: utf8.encode(jsonData).length,
        filePath: filePath,
      );

      // Update metadata
      await _updateMetadataEntry(key, entry);

      _telemetryCallback?.call('cache_set', {
        'key': key,
        'size': entry.size,
        'ttl': ttl?.inMinutes,
      });
    } catch (e) {
      _telemetryCallback?.call('cache_set_error', {'key': key, 'error': e.toString()});
      rethrow;
    }
  }

  /// Remove entry from cache
  Future<void> remove(String key) async {
    await _removeEntry(key);
    _telemetryCallback?.call('cache_remove', {'key': key});
  }

  /// Clear all cache entries
  Future<void> clear() async {
    try {
      final metadata = await _getMetadata();
      // cache directory not needed for metadata clearing

      // Delete all cache files
      for (final entry in metadata.values) {
        try {
          final file = File(entry.filePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          // Continue with other files
        }
      }

      // Clear metadata
      await _prefs.remove(_metadataKey);
      await _prefs.remove(_metricsKey);

      _hitCount = 0;
      _missCount = 0;

      _telemetryCallback?.call('cache_clear', {});
    } catch (e) {
      _telemetryCallback?.call('cache_clear_error', {'error': e.toString()});
    }
  }

  /// Check if key exists in cache
  Future<bool> has(String key) async {
    final metadata = await _getMetadata();
    return metadata.containsKey(key);
  }

  /// Get cache health metrics
  Future<CacheMetrics> getMetrics() async {
    final metadata = await _getMetadata();

    var staleEntries = 0;
    var expiredEntries = 0;
    var totalSize = 0;

    for (final entry in metadata.values) {
      totalSize += entry.size;
      if (entry.isStale) staleEntries++;
      if (entry.isExpired) expiredEntries++;
    }

    final totalRequests = _hitCount + _missCount;
    final hitRate = totalRequests > 0 ? (_hitCount / totalRequests) * 100 : 0.0;

    return CacheMetrics(
      totalEntries: metadata.length,
      staleEntries: staleEntries,
      expiredEntries: expiredEntries,
      totalSize: totalSize,
      hitRate: hitRate,
      missCount: _missCount,
      hitCount: _hitCount,
    );
  }

  /// Clean up expired entries
  Future<void> cleanup() async {
    final metadata = await _getMetadata();
    final toRemove = <String>[];

    for (final entry in metadata.entries) {
      if (entry.value.isExpired) {
        try {
          final file = File(entry.value.filePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          // Continue
        }
        toRemove.add(entry.key);
      }
    }

    if (toRemove.isNotEmpty) {
      final updatedMetadata = Map<String, CacheEntry>.from(metadata);
      for (final key in toRemove) {
        updatedMetadata.remove(key);
      }
      await _saveMetadata(updatedMetadata);
      _telemetryCallback?.call('cache_cleanup', {'removed': toRemove.length});
    }
  }

  /// Get cache directory
  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(appDir.path, _cacheDir));

    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    return cacheDir;
  }

  /// Get metadata from SharedPreferences
  Future<Map<String, CacheEntry>> _getMetadata() async {
    final metadataJson = _prefs.getString(_metadataKey);
    if (metadataJson == null) return {};

    try {
      final data = json.decode(metadataJson) as Map<String, dynamic>;
      return data.map((key, value) => MapEntry(key, CacheEntry.fromJson(value as Map<String, dynamic>)));
    } catch (e) {
      // Corrupted metadata, reset
      await _prefs.remove(_metadataKey);
      return {};
    }
  }

  /// Save metadata to SharedPreferences
  Future<void> _saveMetadata(Map<String, CacheEntry> metadata) async {
    final data = metadata.map((key, value) => MapEntry(key, value.toJson()));
    await _prefs.setString(_metadataKey, json.encode(data));
  }

  /// Update a single metadata entry
  Future<void> _updateMetadataEntry(String key, CacheEntry entry) async {
    final metadata = await _getMetadata();
    metadata[key] = entry;
    await _saveMetadata(metadata);
  }

  /// Remove an entry
  Future<void> _removeEntry(String key) async {
    final metadata = await _getMetadata();
    final entry = metadata.remove(key);

    if (entry != null) {
      try {
        final file = File(entry.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // File might already be deleted
      }
    }

    await _saveMetadata(metadata);
  }

  /// Load metrics from storage
  Future<void> _loadMetrics() async {
    final metricsJson = _prefs.getString(_metricsKey);
    if (metricsJson != null) {
      try {
        final data = json.decode(metricsJson) as Map<String, dynamic>;
        _hitCount = (data['hitCount'] as num?)?.toInt() ?? 0;
        _missCount = (data['missCount'] as num?)?.toInt() ?? 0;
      } catch (e) {
        // Reset metrics
        _hitCount = 0;
        _missCount = 0;
      }
    }
  }
}