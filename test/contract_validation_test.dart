import 'package:flutter_test/flutter_test.dart';
import 'package:gulflands/core/utils/land_plot_validator.dart' as validator;
import 'package:gulflands/domain/entities/land_plot.dart';

void main() {
  setUpAll(() async {
    await validator.LandPlotValidator.initialize();
  });

  group('Data Contract Validation', () {
    test('valid land plot data passes validation', () {
      final validData = {
        'id': 'test-1',
        'title': 'Test Plot',
        'description': 'A test land plot',
        'price': 1000000.0,
        'area': 5000.0,
        'country': 'saudiArabia',
        'location': 'Test City',
        'imageUrls': ['https://example.com/image.jpg'],
        'createdAt': '2023-01-01T00:00:00.000Z',
        'isFeatured': false,
      };

      expect(validator.LandPlotValidator.validate(validData), true);
      expect(validator.LandPlotValidator.getErrors(validData), isEmpty);
    });

    test('invalid data fails validation', () {
      final invalidData = {
        'id': '', // Empty ID
        'title': '', // Empty title
        'price': -1000.0, // Negative price
        'area': 5000.0,
        'country': 'invalidCountry', // Invalid country
        'location': 'Test City',
        'imageUrls': <String>[], // Empty image URLs
        'createdAt': '2023-01-01T00:00:00.000Z',
      };

      expect(validator.LandPlotValidator.validate(invalidData), false);
      final errors = validator.LandPlotValidator.getErrors(invalidData);
      expect(errors.length, greaterThan(0));
    });

    test('LandPlot.fromJson validates data', () {
      final validJson = {
        'id': 'test-1',
        'title': 'Test Plot',
        'description': 'A test land plot',
        'price': 1000000.0,
        'area': 5000.0,
        'country': 'saudiArabia',
        'location': 'Test City',
        'imageUrls': ['https://example.com/image.jpg'],
        'createdAt': '2023-01-01T00:00:00.000Z',
        'isFeatured': false,
      };

      expect(() => LandPlot.fromJson(validJson), returnsNormally);
      final plot = LandPlot.fromJson(validJson);
      expect(plot.id, 'test-1');
      expect(plot.title, 'Test Plot');
    });

    test('LandPlot.fromJson throws on invalid data', () {
      final invalidJson = {
        'id': '',
        'title': '',
        'description': 'A test land plot',
        'price': -1000.0,
        'area': 5000.0,
        'country': 'invalidCountry',
        'location': 'Test City',
        'imageUrls': <String>[],
        'createdAt': '2023-01-01T00:00:00.000Z',
      };

      expect(() => LandPlot.fromJson(invalidJson), throwsA(isA<FormatException>()));
    });
  });
}
