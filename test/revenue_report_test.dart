import 'package:flutter_test/flutter_test.dart';
import 'package:luxestay/services/firestore_service.dart';

void main() {
  test('weekly report includes only paid bookings in the selected week', () {
    final report = createRevenueReport(
      properties: [
        {'id': 'beach', 'name': 'Beach Resort'},
        {'id': 'city', 'name': 'City Hotel'},
      ],
      bookings: [
        {
          'propertyId': 'beach',
          'paymentStatus': 'paid',
          'totalPrice': 250,
          'createdAt': DateTime(2026, 10, 5),
        },
        {
          'propertyId': 'beach',
          'paymentStatus': 'PAID',
          'totalPrice': '75',
          'createdAt': DateTime(2026, 10, 9),
        },
        {
          'propertyId': 'city',
          'paymentStatus': 'unpaid',
          'totalPrice': 900,
          'createdAt': DateTime(2026, 10, 9),
        },
        {
          'propertyId': 'removed',
          'paymentStatus': 'paid',
          'totalPrice': 500,
          'createdAt': DateTime(2026, 10, 8),
        },
        {
          'propertyId': 'beach',
          'paymentStatus': 'paid',
          'totalPrice': 600,
          'createdAt': DateTime(2026, 10, 12),
        },
      ],
      period: RevenuePeriod.week,
      now: DateTime(2026, 10, 10),
    );

    expect(report.totalRevenue, 325);
    expect(report.paidBookingCount, 2);
    expect(
      report.properties
          .map((property) => (property.propertyId, property.revenue))
          .toList(),
      [('beach', 325), ('city', 0)],
    );
    expect(report.trend.map((point) => point.revenue).toList(), [
      250,
      0,
      0,
      0,
      75,
      0,
      0,
    ]);
  });

  test('monthly and yearly reports use weekly and monthly chart buckets', () {
    final bookings = [
      {
        'propertyId': 'beach',
        'paymentStatus': 'paid',
        'totalPrice': 100,
        'createdAt': DateTime(2026, 1, 15),
      },
      {
        'propertyId': 'beach',
        'paymentStatus': 'paid',
        'totalPrice': 200,
        'createdAt': DateTime(2026, 10, 2),
      },
      {
        'propertyId': 'beach',
        'paymentStatus': 'paid',
        'totalPrice': 300,
        'createdAt': DateTime(2026, 10, 25),
      },
    ];
    const properties = [
      {'id': 'beach', 'name': 'Beach Resort'},
    ];

    final monthly = createRevenueReport(
      properties: properties,
      bookings: bookings,
      period: RevenuePeriod.month,
      now: DateTime(2026, 10, 10),
    );
    final yearly = createRevenueReport(
      properties: properties,
      bookings: bookings,
      period: RevenuePeriod.year,
      now: DateTime(2026, 10, 10),
    );

    expect(monthly.totalRevenue, 500);
    expect(
      monthly.trend.map((point) => point.revenue).toList(),
      [200, 0, 0, 300, 0],
    );
    expect(yearly.totalRevenue, 600);
    expect(yearly.trend.map((point) => point.revenue).toList(), [
      100,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      500,
      0,
      0,
    ]);
  });
}
