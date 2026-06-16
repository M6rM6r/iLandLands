import 'package:gulflands/core/services/telemetry_service.dart';
import 'package:gulflands/core/storage/cache_repository.dart';

abstract class CacheManager {
  Future<T?> get<T>(String key);
  Future<void> set<T>(String key, T value, {Duration? ttl});
  Future<void> remove(String key);
  Future<void> clear();
  Future<bool> has(String key);
}

class CacheManagerImpl implements CacheManager {
  CacheManagerImpl._(this._cacheRepository);
  final CacheRepository _cacheRepository;

  static Future<CacheManagerImpl> create({
    TelemetryHooks? telemetryHooks,
  }) async {
    final CacheRepository cacheRepo = await CacheRepository.initialize(
      telemetryCallback: telemetryHooks?.cacheCallback,
    );
    return CacheManagerImpl._(cacheRepo);
  }

  @override
  Future<T?> get<T>(String key) => _cacheRepository.get<T>(key);

  @override
  Future<void> set<T>(String key, T value, {Duration? ttl}) =>
      _cacheRepository.set(key, value, ttl: ttl);

  @override
  Future<void> remove(String key) => _cacheRepository.remove(key);

  @override
  Future<void> clear() => _cacheRepository.clear();

  @override
  Future<bool> has(String key) => _cacheRepository.has(key);

  /// Get cache metrics
  Future<CacheMetrics> getMetrics() => _cacheRepository.getMetrics();

  /// Cleanup expired entries
  Future<void> cleanup() => _cacheRepository.cleanup();
}
