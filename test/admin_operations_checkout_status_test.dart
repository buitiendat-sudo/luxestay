import 'package:flutter_test/flutter_test.dart';
import 'package:luxestay/seed_data.dart';
import 'package:luxestay/screens/admin/admin_operations_screen.dart';

void main() {
  group('booking lifecycle status helpers', () {
    test('check-in transitions are consistent with the admin workflow', () {
      expect(checkInStatusTransition('pending'), 'confirmed');
      expect(checkInStatusTransition('waiting'), 'confirmed');
      expect(checkInStatusTransition('confirmed'), 'checked_in');
    });

    test('check-out transitions complete the stay lifecycle', () {
      expect(checkOutStatusTransition('checked_in'), 'checked_out');
      expect(checkOutStatusTransition('checked_out'), 'completed');
      expect(checkOutStatusTransition('completed'), 'completed');
    });
  });

  group('property revenue ranking', () {
    final properties = [
      {'id': 'p1', 'name': 'Luxe North'},
      {'id': 'p2', 'name': 'Luxe Central'},
      {'id': 'p3', 'name': 'Luxe Coast'},
      {'id': 'p4', 'name': 'Luxe South'},
    ];
    final bookings = [
      {
        'propertyId': 'p1',
        'paymentStatus': 'paid',
        'totalPrice': 100,
        'createdAt': DateTime(2026, 3, 16),
      },
      {
        'propertyId': 'p2',
        'paymentStatus': 'paid',
        'totalPrice': 200,
        'createdAt': DateTime(2026, 3, 17),
      },
      {
        'propertyId': 'p1',
        'paymentStatus': 'paid',
        'totalPrice': 50,
        'createdAt': DateTime(2026, 3, 18),
      },
      {
        'propertyId': 'p3',
        'paymentStatus': 'paid',
        'totalPrice': 900,
        'createdAt': DateTime(2026, 3, 15),
      },
      {
        'propertyId': 'p2',
        'paymentStatus': 'unpaid',
        'totalPrice': 700,
        'createdAt': DateTime(2026, 3, 18),
      },
      {
        'propertyId': 'p4',
        'paymentStatus': 'paid',
        'totalPrice': 75,
        'createdAt': DateTime(2026, 3, 9),
      },
    ];

    test('ranks paid properties for the current Monday-based week', () {
      final rankings = rankPropertiesByRevenue(
        properties: properties,
        bookings: bookings,
        today: DateTime(2026, 3, 18),
        period: 'Tuần này',
      );

      expect(rankings.map((rank) => (rank.propertyId, rank.revenue)).toList(), [
        ('p2', 200),
        ('p1', 150),
      ]);
    });

    test('ranks only paid properties within the current calendar month', () {
      final rankings = rankPropertiesByRevenue(
        properties: properties,
        bookings: bookings,
        today: DateTime(2026, 3, 18),
        period: 'Tháng này',
      );

      expect(rankings.map((rank) => (rank.propertyId, rank.revenue)).toList(), [
        ('p3', 900),
        ('p2', 200),
        ('p1', 150),
      ]);
    });

    test('ranks paid properties for today only', () {
      final rankings = rankPropertiesByRevenue(
        properties: properties,
        bookings: bookings,
        today: DateTime(2026, 3, 18),
        period: 'Hôm nay',
      );

      expect(rankings.map((rank) => (rank.propertyId, rank.revenue)).toList(), [
        ('p1', 50),
      ]);
    });

    test('demo seed creates varied weekly and monthly revenue rankings', () {
      final samples = SeedData.bookingSamples(now: DateTime(2026, 10, 9));
      final properties = [
        {'id': 'vinpearl-phu-quoc', 'name': 'Vinpearl'},
        {'id': 'intercontinental-phu-quoc', 'name': 'InterContinental'},
        {'id': 'premier-village-phu-quoc', 'name': 'Premier Village'},
        {'id': 'fusion-resort-phu-quoc', 'name': 'Fusion'},
        {'id': 'salinda-resort-phu-quoc', 'name': 'Salinda'},
        {'id': 'novotel-phu-quoc', 'name': 'Novotel'},
        {'id': 'dusit-princess-phu-quoc', 'name': 'Dusit Princess'},
        {'id': 'la-mer-resort-phu-quoc', 'name': 'La Mer'},
      ];
      final bookings = samples.values.toList();
      final today = DateTime(2026, 10, 9);
      final weeklyTop = rankPropertiesByRevenue(
        properties: properties,
        bookings: bookings,
        today: today,
        period: 'Tuần này',
      );
      final monthlyTop = rankPropertiesByRevenue(
        properties: properties,
        bookings: bookings,
        today: today,
        period: 'Tháng này',
      );

      expect(samples, hasLength(15));
      expect(
        samples.values.any((booking) => booking['paymentStatus'] == 'unpaid'),
        isTrue,
      );
      expect(
        samples.values.every(
          (booking) =>
              booking['isDemo'] == true &&
              booking['customerName'] != null &&
              booking['customerEmail'] != null &&
              booking['customerPhone'] != null &&
              booking['bookingReference'] != null &&
              booking['bookingChannel'] == 'mobile_app' &&
              booking['totalPrice'] ==
                  (booking['pricePerNight'] as int) *
                      (booking['totalNights'] as int),
        ),
        isTrue,
      );
      expect(
        samples.values.map((booking) => booking['bookingReference']).toSet(),
        hasLength(samples.length),
      );
      expect(weeklyTop.map((rank) => rank.propertyId).toList(), [
        'premier-village-phu-quoc',
        'intercontinental-phu-quoc',
        'vinpearl-phu-quoc',
      ]);
      expect(monthlyTop.map((rank) => rank.propertyId).toList(), [
        'salinda-resort-phu-quoc',
        'novotel-phu-quoc',
        'dusit-princess-phu-quoc',
      ]);
    });
  });

  group('revenue trend points', () {
    final bookings = [
      {
        'paymentStatus': 'paid',
        'totalPrice': 50,
        'createdAt': DateTime(2026, 3, 18, 11),
      },
      {
        'paymentStatus': 'paid',
        'totalPrice': 60,
        'createdAt': DateTime(2026, 3, 18, 17),
      },
      {
        'paymentStatus': 'paid',
        'totalPrice': 100,
        'createdAt': DateTime(2026, 3, 17, 13),
      },
      {
        'paymentStatus': 'paid',
        'totalPrice': 200,
        'createdAt': DateTime(2026, 3, 1, 9),
      },
      {
        'paymentStatus': 'unpaid',
        'totalPrice': 900,
        'createdAt': DateTime(2026, 3, 18, 12),
      },
    ];

    test('groups paid revenue into today, week and month chart buckets', () {
      final today = DateTime(2026, 3, 18);
      final daily = revenueTrendPoints(
        bookings: bookings,
        today: today,
        period: 'Hôm nay',
      );
      final weekly = revenueTrendPoints(
        bookings: bookings,
        today: today,
        period: 'Tuần này',
      );
      final monthly = revenueTrendPoints(
        bookings: bookings,
        today: today,
        period: 'Tháng này',
      );

      expect(daily.map((point) => point.revenue).toList(), [
        0,
        0,
        50,
        0,
        60,
        0,
      ]);
      expect(weekly.map((point) => point.revenue).toList(), [
        0,
        100,
        110,
        0,
        0,
        0,
        0,
      ]);
      expect(monthly.map((point) => point.revenue).toList(), [
        200,
        0,
        210,
        0,
        0,
      ]);
    });
  });
}
