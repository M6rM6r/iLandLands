import 'package:gulflands/core/network/api_client.dart';

class InquiryRepository {
  InquiryRepository({ApiClient? apiClient})
      : _api = apiClient ?? ApiClientImpl();

  final ApiClient _api;

  static const String _endpoint = '/inquiries';

  Future<void> submitInquiry({
    required String name,
    required String email,
    required String phone,
    required String message,
    String? landId,
    String? landTitle,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone,
      'message': message,
      if (landId != null) 'land_id': landId,
      if (landTitle != null) 'listing_title': landTitle,
    };
    await _api.post(_endpoint, body);
  }
}
