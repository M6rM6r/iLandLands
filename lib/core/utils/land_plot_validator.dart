// Dart validator using the schema
import 'dart:convert';
import 'package:json_schema/json_schema.dart';

class LandPlotValidator {
  static JsonSchema? _schema;

  static Future<void> initialize() async {
    if (_schema != null) return;
    
    const schemaString = r'''
    {
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      "type": "object",
      "properties": {
        "id": {"type": "string"},
        "title": {"type": "string", "minLength": 1, "maxLength": 200},
        "description": {"type": "string", "minLength": 1, "maxLength": 2000},
        "price": {"type": "number", "minimum": 0},
        "area": {"type": "number", "minimum": 0},
        "country": {"type": "string", "enum": ["saudiArabia", "uae", "qatar", "bahrain", "oman", "kuwait"]},
        "location": {"type": "string", "minLength": 1, "maxLength": 200},
        "imageUrls": {"type": "array", "items": {"type": "string", "format": "uri"}, "minItems": 1},
        "isFeatured": {"type": "boolean"},
        "createdAt": {"type": "string", "format": "date-time"},
        "updatedAt": {"type": "string", "format": "date-time"}
      },
      "required": ["id", "title", "description", "price", "area", "country", "location", "imageUrls", "createdAt"]
    }
    ''';

    _schema = JsonSchema.create(jsonDecode(schemaString) as Map<String, dynamic>);
  }

  static bool validate(Map<String, dynamic> data) {
    if (_schema == null) throw StateError('Schema not initialized');
    final result = _schema!.validate(data);
    return result.isValid;
  }

  static List<String> getErrors(Map<String, dynamic> data) {
    if (_schema == null) throw StateError('Schema not initialized');
    final result = _schema!.validate(data);
    return result.errors.map((e) => e.message).toList();
  }
}