import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:luxestay/services/google_geocoding_service.dart';

void main() {
  group('GoogleGeocodingService', () {
    test(
      'parses coordinates and includes the hotel address in the request',
      () async {
        final client = _FakeClient(
          jsonEncode({
            'status': 'OK',
            'results': [
              {
                'formatted_address': 'Bãi Dài, Phú Quốc, Việt Nam',
                'geometry': {
                  'location': {'lat': 10.3333, 'lng': 103.9},
                  'location_type': 'ROOFTOP',
                },
              },
            ],
          }),
        );
        final service = GoogleGeocodingService(
          client: client,
          apiKey: 'test-key',
        );
        addTearDown(service.close);

        final result = await service.geocodeHotel(
          name: 'Vinpearl Resort',
          address: 'Bãi Dài',
          location: 'Phú Quốc',
        );

        expect(result.latitude, 10.3333);
        expect(result.longitude, 103.9);
        expect(result.locationType, 'ROOFTOP');
        expect(
          client.requestedUri!.queryParameters['address'],
          contains('Bãi Dài'),
        );
        expect(
          client.requestedUri!.queryParameters['components'],
          'country:VN',
        );
      },
    );

    test('reports when Google has no matching result', () async {
      final service = GoogleGeocodingService(
        client: _FakeClient(
          jsonEncode({'status': 'ZERO_RESULTS', 'results': []}),
        ),
        apiKey: 'test-key',
      );
      addTearDown(service.close);

      await expectLater(
        service.geocodeHotel(name: 'Unknown Resort', location: 'Phú Quốc'),
        throwsA(isA<GoogleGeocodingException>()),
      );
    });

    test('reports a timeout when Google responds too slowly', () async {
      final service = GoogleGeocodingService(
        client: _FakeClient(
          jsonEncode({'status': 'OK', 'results': []}),
          delay: const Duration(milliseconds: 20),
        ),
        apiKey: 'test-key',
        timeout: const Duration(milliseconds: 1),
      );
      addTearDown(service.close);

      await expectLater(
        service.geocodeHotel(name: 'Slow Resort', location: 'Phú Quốc'),
        throwsA(
          isA<GoogleGeocodingException>().having(
            (error) => error.message,
            'message',
            contains('phản hồi quá chậm'),
          ),
        ),
      );
    });
  });
}

class _FakeClient extends http.BaseClient {
  _FakeClient(this.responseBody, {this.delay = Duration.zero});

  final String responseBody;
  final Duration delay;
  Uri? requestedUri;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestedUri = request.url;
    await Future<void>.delayed(delay);
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(responseBody)),
      200,
    );
  }
}
