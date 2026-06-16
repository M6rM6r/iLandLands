import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gulflands/core/config/app_config.dart';
import 'package:http/http.dart' as http;

abstract class ApiClient {
  Future<dynamic> get(String endpoint);
  Future<dynamic> post(String endpoint, Map<String, dynamic> data);
  Future<dynamic> put(String endpoint, Map<String, dynamic> data);
  Future<dynamic> delete(String endpoint);
}

class ApiClientImpl implements ApiClient {
  ApiClientImpl({http.Client? client, Connectivity? connectivity})
    : _client = client ?? http.Client(),
      _connectivity = connectivity ?? Connectivity();
  static String get _baseUrl => AppConfig.apiBaseUrl;
  static Duration get _timeout => AppConfig.apiTimeout;

  final http.Client _client;
  final Connectivity _connectivity;

  @override
  Future<dynamic> get(String endpoint) async {
    return _request('GET', endpoint);
  }

  @override
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    return _request('POST', endpoint, body: data);
  }

  @override
  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    return _request('PUT', endpoint, body: data);
  }

  @override
  Future<dynamic> delete(String endpoint) async {
    return _request('DELETE', endpoint);
  }

  Future<dynamic> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      // Check connectivity
      final List<ConnectivityResult> connectivityResult = await _connectivity
          .checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        throw NetworkException('No internet connection');
      }

      final Uri uri = Uri.parse('$_baseUrl$endpoint');
      final Map<String, String> headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      http.Response response;

      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers).timeout(_timeout);
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: json.encode(body))
              .timeout(_timeout);
        case 'PUT':
          response = await _client
              .put(uri, headers: headers, body: json.encode(body))
              .timeout(_timeout);
        case 'DELETE':
          response = await _client
              .delete(uri, headers: headers)
              .timeout(_timeout);
        default:
          throw UnsupportedError('Method $method is not supported');
      }

      return _handleResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return json.decode(response.body);
      case 400:
        final Map<String, dynamic> body =
            json.decode(response.body) as Map<String, dynamic>;
        throw BadRequestException(body['message'] as String? ?? 'Bad request');
      case 401:
        throw UnauthorizedException('Unauthorized access');
      case 403:
        throw ForbiddenException('Access forbidden');
      case 404:
        throw NotFoundException('Resource not found');
      case 500:
        throw ServerException('Internal server error');
      default:
        throw ApiException(
          'Request failed with status: ${response.statusCode}',
        );
    }
  }

  Exception _handleError(dynamic error) {
    if (error is Exception) return error;

    if (error.toString().contains('SocketException')) {
      return NetworkException('Network connection failed');
    }

    if (error.toString().contains('TimeoutException')) {
      return NetworkException('Request timeout');
    }

    return ApiException('An unexpected error occurred: $error');
  }
}

// Custom exception classes
class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException(super.message);
}

class BadRequestException extends ApiException {
  BadRequestException(super.message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message);
}

class ForbiddenException extends ApiException {
  ForbiddenException(super.message);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message);
}

class ServerException extends ApiException {
  ServerException(super.message);
}
