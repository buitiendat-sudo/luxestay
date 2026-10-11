import 'package:flutter_test/flutter_test.dart';
import 'package:luxestay/models/property.dart';
import 'package:luxestay/services/ai_travel_service.dart';
import 'package:luxestay/services/firestore_service.dart';

void main() {
  test('does not use hotels outside the requested destination', () async {
    final service = AiTravelService(
      _FakeFirestoreService([
        const Property(
          id: 'da-nang-property',
          name: 'Beach Hotel',
          location: 'Đà Nẵng',
          image: '',
          rating: 4.5,
          reviewCount: 10,
          pricePerNight: 1000000,
          amenities: [],
          category: 'Hotel',
        ),
      ]),
    );

    await expectLater(
      service.generateTravelPlan(
        destination: 'Hà Nội',
        days: 2,
        guests: 2,
        budget: 5000000,
      ),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Không tìm thấy phòng khách sạn phù hợp'),
        ),
      ),
    );
  });
}

class _FakeFirestoreService implements FirestoreService {
  _FakeFirestoreService(this.inventoryProperties);

  final List<Property> inventoryProperties;

  @override
  Stream<List<Property>> getProperties() => Stream.value(inventoryProperties);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}