import 'package:flutter_test/flutter_test.dart';
import 'package:luxestay/services/firestore_service.dart';

void main() {
  test('summarizes valid reviews by property', () {
    final summaries = summarizePropertyReviews([
      {'propertyId': 'hotel-a', 'rating': 5},
      {'propertyId': 'hotel-a', 'rating': 3},
      {'propertyId': 'hotel-b', 'rating': 4},
      {'propertyId': 'hotel-a', 'rating': 0},
    ]);

    expect(summaries['hotel-a']?.rating, 4);
    expect(summaries['hotel-a']?.count, 2);
    expect(summaries['hotel-b']?.rating, 4);
    expect(summaries['hotel-b']?.count, 1);
  });
}