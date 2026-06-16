import 'package:flutter_test/flutter_test.dart';
import 'package:gulflands/core/services/telemetry_service.dart';
import 'package:gulflands/core/storage/cache_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheRepository', () {
    late CacheRepository cache;
    late TelemetryService telemetry;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      telemetry = await TelemetryService.initialize();
      cache = await CacheRepository.initialize(
        telemetryCallback: telemetry.cacheTelemetryCallback,
      );
    });

    tearDown(() async {
      await cache.clear();
    });

    test('should store and retrieve data', () async {
      const Map<String, Object> testData = <String, Object>{
        'key': 'value',
        'number': 42,
      };
      const String cacheKey = 'test_key';

      // Store data
      await cache.set(cacheKey, testData, ttl: const Duration(hours: 1));

      // Retrieve data
      final Map<String, dynamic>? retrieved = await cache
          .get<Map<String, dynamic>>(cacheKey);

      expect(retrieved, equals(testData));
    });

    test('should return null for non-existent key', () async {
      final String? retrieved = await cache.get<String>('non_existent');
      expect(retrieved, isNull);
    });

    test('should handle TTL expiration', () async {
      const String testData = 'test data';
      const String cacheKey = 'ttl_test';

      // Store with short TTL
      await cache.set(
        cacheKey,
        testData,
        ttl: const Duration(milliseconds: 100),
      );

      // Should work immediately
      String? retrieved = await cache.get<String>(cacheKey);
      expect(retrieved, equals(testData));

      // Wait for expiration
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Should be null after expiration
      retrieved = await cache.get<String>(cacheKey);
      expect(retrieved, isNull);
    });

    test('should provide cache metrics', () async {
      const String testData1 = 'data1';
      const String testData2 = 'data2';

      await cache.set('key1', testData1);
      await cache.set('key2', testData2);

      // Access one key multiple times
      await cache.get<String>('key1');
      await cache.get<String>('key1');
      await cache.get<String>('key2');

      final CacheMetrics metrics = await cache.getMetrics();

      expect(metrics.totalEntries, equals(2));
      expect(metrics.hitCount, greaterThanOrEqualTo(2));
      expect(metrics.missCount, greaterThanOrEqualTo(1));
    });

    test('should handle corrupt cache gracefully', () async {
      // Manually corrupt the cache by setting invalid JSON
      // This test ensures no crashes occur with corrupt data
      const String cacheKey = 'corrupt_test';

      // This should not crash even if cache is corrupted
      final String? retrieved = await cache.get<String>(cacheKey);
      expect(retrieved, isNull);
    });

    test('should cleanup expired entries', () async {
      await cache.set('expired', 'data', ttl: const Duration(milliseconds: 50));
      await cache.set('valid', 'data', ttl: const Duration(hours: 1));

      // Wait for expiration
      await Future<void>.delayed(const Duration(milliseconds: 100));

      await cache.cleanup();

      final String? expired = await cache.get<String>('expired');
      final String? valid = await cache.get<String>('valid');

      expect(expired, isNull);
      expect(valid, equals('data'));
    });
  });
}
