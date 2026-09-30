import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class GeoCoordinates {
  const GeoCoordinates({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.locationType,
  });

  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String locationType;
}

class GoogleGeocodingException implements Exception {
  const GoogleGeocodingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GoogleGeocodingService {
  GoogleGeocodingService({
    http.Client? client,
    String? apiKey,
    this.timeout = const Duration(seconds: 15),
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ?? const String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  final http.Client _client;
  final String _apiKey;
  final Duration timeout;

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Future<GeoCoordinates> geocodeHotel({
    required String name,
    required String location,
    String? address,
  }) async {
    if (!isConfigured) {
      throw const GoogleGeocodingException(
        'Chưa cấu hình GOOGLE_MAPS_API_KEY. Hãy chạy ứng dụng với '
        '--dart-define=GOOGLE_MAPS_API_KEY=YOUR_API_KEY.',
      );
    }

    final query = [
      name.trim(),
      if (address != null && address.trim().isNotEmpty) address.trim(),
      location.trim(),
      'Vietnam',
    ].where((part) => part.isNotEmpty).join(', ');

    if (name.trim().isEmpty || location.trim().isEmpty) {
      throw const GoogleGeocodingException(
        'Resort cần có tên và địa điểm trước khi lấy tọa độ.',
      );
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      {
        'address': query,
        'components': 'country:VN',
        'key': _apiKey,
      },
    );
    final http.Response response;
    try {
      response = await _client.get(uri).timeout(timeout);
    } on TimeoutException {
      throw const GoogleGeocodingException(
        'Google Geocoding API phản hồi quá chậm. Hãy thử lại.',
      );
    }

    if (response.statusCode != 200) {
      throw GoogleGeocodingException(
        'Google Geocoding API trả về HTTP ${response.statusCode}.',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const GoogleGeocodingException(
        'Phản hồi từ Google Geocoding API không hợp lệ.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const GoogleGeocodingException(
        'Phản hồi từ Google Geocoding API không đúng định dạng.',
      );
    }

    final status = decoded['status'] as String? ?? 'UNKNOWN_ERROR';
    if (status != 'OK') {
      throw GoogleGeocodingException(_statusMessage(status));
    }

    final results = decoded['results'];
    if (results is! List || results.isEmpty) {
      throw const GoogleGeocodingException(
        'Không tìm thấy tọa độ. Hãy bổ sung địa chỉ chi tiết cho resort.',
      );
    }

    final firstResult = results.first;
    if (firstResult is! Map<String, dynamic>) {
      throw const GoogleGeocodingException(
        'Kết quả tọa độ từ Google không đúng định dạng.',
      );
    }

    final geometry = firstResult['geometry'];
    final coordinates =
        geometry is Map<String, dynamic> ? geometry['location'] : null;
    if (coordinates is! Map<String, dynamic>) {
      throw const GoogleGeocodingException(
        'Google không trả về tọa độ cho địa điểm này.',
      );
    }

    final latitude = coordinates['lat'];
    final longitude = coordinates['lng'];
    if (latitude is! num ||
        longitude is! num ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw const GoogleGeocodingException(
        'Tọa độ Google trả về không hợp lệ.',
      );
    }

    return GeoCoordinates(
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      formattedAddress: firstResult['formatted_address'] as String? ?? '',
      locationType: geometry['location_type'] as String? ?? '',
    );
  }

  void close() => _client.close();

  String _statusMessage(String status) {
    return switch (status) {
      'ZERO_RESULTS' =>
        'Không tìm thấy tọa độ. Hãy bổ sung địa chỉ chi tiết cho resort.',
      'OVER_QUERY_LIMIT' =>
        'Đã vượt hạn mức Google Geocoding API. Hãy kiểm tra quota/billing.',
      'REQUEST_DENIED' =>
        'Google từ chối yêu cầu. Kiểm tra API Geocoding đã bật, billing '
            'và giới hạn của API key.',
      'INVALID_REQUEST' =>
        'Địa chỉ gửi tới Google không hợp lệ.',
      'UNKNOWN_ERROR' =>
        'Google Geocoding API gặp lỗi tạm thời. Hãy thử lại.',
      _ => 'Google Geocoding API trả về trạng thái $status.',
    };
  }
}
