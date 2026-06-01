import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gulflands/core/storage/cache_repository.dart';

/// Sync operation result
class SyncResult {

  const SyncResult({
    required this.success,
    this.error,
    this.duration,
    this.itemsSynced = 0,
  });
  final bool success;
  final String? error;
  final Duration? duration;
  final int itemsSynced;
}

/// Sync strategy for different data types
enum SyncStrategy {
  /// Always try network first, fallback to cache
  networkFirst,
  /// Always use cache first, sync in background
  cacheFirst,
  /// Only sync when explicitly requested
  manual,
}

/// Configuration for sync operations
class SyncConfig {

  const SyncConfig({
    this.syncInterval = const Duration(minutes: 15),
    this.staleWhileRevalidateWindow = const Duration(hours: 1),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 5),
    this.strategy = SyncStrategy.networkFirst,
  });
  final Duration syncInterval;
  final Duration staleWhileRevalidateWindow;
  final int maxRetries;
  final Duration retryDelay;
  final SyncStrategy strategy;
}

/// Sync manager for offline-first data synchronization
class SyncManager {

  SyncManager(
    this._cache,
    this._connectivity, {
    SyncConfig? config,
  }) : _config = config ?? const SyncConfig();
  final CacheRepository _cache;
  final Connectivity _connectivity;
  final SyncConfig _config;

  final StreamController<SyncResult> _syncController = StreamController<SyncResult>.broadcast();
  Timer? _syncTimer;
  bool _isOnline = true;

  /// Stream of sync results
  Stream<SyncResult> get syncResults => _syncController.stream;

  /// Initialize the sync manager
  Future<void> initialize() async {
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);

    // Check initial connectivity
    final results = await _connectivity.checkConnectivity();
    _isOnline = !results.contains(ConnectivityResult.none);

    // Start periodic sync if online
    if (_isOnline) {
      _startPeriodicSync();
    }
  }

  /// Dispose of resources
  void dispose() {
    _syncTimer?.cancel();
    _syncController.close();
  }

  /// Sync data with retry logic
  Future<SyncResult> sync<T>({
    required String key,
    required Future<T> Function() fetchFromNetwork,
    required Future<void> Function(T data) onSyncSuccess,
    Duration? ttl,
  }) async {
    final startTime = DateTime.now();

    if (!_isOnline) {
      return const SyncResult(
        success: false,
        error: 'No internet connection',
      );
    }

    var attempt = 0;
    while (attempt < _config.maxRetries) {
      try {
        final data = await fetchFromNetwork();
        await _cache.set(key, data, ttl: ttl);
        await onSyncSuccess(data);

        final duration = DateTime.now().difference(startTime);
        final result = SyncResult(
          success: true,
          duration: duration,
          itemsSynced: 1,
        );

        _syncController.add(result);
        return result;
      } catch (e) {
        attempt++;
        if (attempt < _config.maxRetries) {
          await Future<void>.delayed(_config.retryDelay * attempt);
        }
      }
    }

    final duration = DateTime.now().difference(startTime);
    final result = SyncResult(
      success: false,
      error: 'Failed after ${_config.maxRetries} attempts',
      duration: duration,
    );

    _syncController.add(result);
    return result;
  }

  /// Get data with offline-first strategy
  Future<T?> getWithSync<T>({
    required String key,
    required Future<T> Function() fetchFromNetwork,
    required Future<void> Function(T data) onSyncSuccess,
    Duration? ttl,
    bool forceRefresh = false,
  }) async {
    // Try cache first
    final cached = await _cache.get<T>(key);
    if (cached != null && !forceRefresh) {
      // Check if we should revalidate in background
      final shouldRevalidate = await _shouldRevalidate(key);
      if (shouldRevalidate && _isOnline) {
        // Revalidate in background
        unawaited(sync(
          key: key,
          fetchFromNetwork: fetchFromNetwork,
          onSyncSuccess: onSyncSuccess,
          ttl: ttl,
        ));
      }
      return cached;
    }

    // Cache miss or force refresh - try network
    if (_isOnline) {
      try {
        final data = await fetchFromNetwork();
        await _cache.set(key, data, ttl: ttl);
        await onSyncSuccess(data);
        return data;
      } catch (e) {
        // Network failed, return stale cache if available
        if (cached != null) {
          return cached;
        }
        rethrow;
      }
    }

    // Offline and no cache
    return cached;
  }

  /// Force a sync operation
  Future<SyncResult> forceSync<T>({
    required String key,
    required Future<T> Function() fetchFromNetwork,
    required Future<void> Function(T data) onSyncSuccess,
    Duration? ttl,
  }) async {
    return sync(
      key: key,
      fetchFromNetwork: fetchFromNetwork,
      onSyncSuccess: onSyncSuccess,
      ttl: ttl,
    );
  }

  /// Check if data should be revalidated
  Future<bool> _shouldRevalidate(String key) async {
    // This is a simplified check - in a real implementation,
    // you'd check the cache entry's timestamp against the revalidate window
    return true; // Always revalidate for now
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = !results.contains(ConnectivityResult.none);

    if (!wasOnline && _isOnline) {
      // Came back online - start sync
      _startPeriodicSync();
      _syncController.add(const SyncResult(
        success: true,
      ));
    } else if (wasOnline && !_isOnline) {
      // Went offline - stop sync
      _syncTimer?.cancel();
      _syncTimer = null;
    }
  }

  /// Start periodic sync timer
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_config.syncInterval, (_) {
      // Perform background sync operations here
      // This could sync multiple keys or perform maintenance
      unawaited(_performBackgroundSync());
    });
  }

  /// Perform background sync operations
  Future<void> _performBackgroundSync() async {
    try {
      // Cleanup expired cache entries
      await _cache.cleanup();

      // Here you could add logic to sync specific keys that need background updates
      // For example, sync user preferences, app config, etc.

    } catch (e) {
      // Background sync errors shouldn't crash the app
    }
  }

  /// Get current connectivity status
  bool get isOnline => _isOnline;

  /// Get sync configuration
  SyncConfig get config => _config;
}