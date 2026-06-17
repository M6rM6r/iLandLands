import 'package:dio/dio.dart';
import '../models/land_plot.dart';
import '../models/land_repository.dart';
import '../core/exceptions.dart';

class LandRepositoryImpl implements LandRepository {
  final Dio _client;
  static const String _endpoint = '/land-plots';

  LandRepositoryImpl(this._client);

  @override
  Future<List<LandPlot>> getLandPlots({
    String? query,
    String? country,
    String? sortBy,
  }) async {
    try {
      final Response<dynamic> response = await _client.get(
        _endpoint,
        queryParameters: <String, dynamic>{
          if (query != null) 'q': query,
          if (country != null) 'country': country,
          if (sortBy != null) 'sort': sortBy,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map<LandPlot>(
              (dynamic json) => LandPlot.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }
      throw ServerFailure('Invalid response', statusCode: response.statusCode);
    } on DioError catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> submitLandPlot(LandPlot plot) async {
    try {
      await _client.post(_endpoint, data: plot.toJson());
    } on DioError catch (e) {
      throw _handleDioError(e);
    }
  }

  Failure _handleDioError(DioError error) {
    if (error.type == DioErrorType.connectionTimeout || error.type == DioErrorType.receiveTimeout) {
      return const NetworkFailure('Connection timed out');
    }

    if (error.type == DioErrorType.response) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      final message = (data is Map)
          ? (data['message'] ?? data['error'] ?? 'Server error')
          : 'Server error';
      return ServerFailure(message.toString(), statusCode: statusCode);
    }

    return UnknownFailure(error.message ?? 'Unknown network error');
  }
}