import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking.dart';
import '../models/property.dart';
import '../models/room.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  CollectionReference<Map<String, dynamic>> get properties =>
      _firestore.collection('properties');

  CollectionReference<Map<String, dynamic>> get bookings =>
      _firestore.collection('bookings');

  CollectionReference<Map<String, dynamic>> get users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get hotels =>
      _firestore.collection('hotels');

  CollectionReference<Map<String, dynamic>> get rooms =>
      _firestore.collection('rooms');

  CollectionReference<Map<String, dynamic>> get reviews =>
      _firestore.collection('reviews');

  // ============================================================
  // PROPERTIES
  // ============================================================

  Stream<List<Property>> getProperties() {
    return properties.snapshots().map(
      (snapshot) =>
          snapshot.docs.map(Property.fromFirestore).toList(growable: false),
    );
  }

  Stream<List<Map<String, dynamic>>> watchProperties() {
    return properties.snapshots().map(_documentsToMaps);
  }

  Stream<List<Map<String, dynamic>>> watchReviewsByProperty(String propertyId) {
    return reviews
        .where('propertyId', isEqualTo: propertyId)
        .snapshots()
        .map(_documentsToMaps);
  }

  Future<void> submitPropertyReview({
    required String userId,
    required String userName,
    required String propertyId,
    required String propertyName,
    required int rating,
    required String comment,
    required bool recommends,
    required String recommendReason,
    required List<String> highlights,
  }) {
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'must be between 1 and 5');
    }

    final reviewId = '${propertyId}_$userId';
    return reviews.doc(reviewId).set({
      'userId': userId,
      'userName': userName.trim().isEmpty ? 'Khách hàng' : userName.trim(),
      'propertyId': propertyId,
      'propertyName': propertyName,
      'rating': rating,
      'comment': comment.trim(),
      'recommends': recommends,
      'recommendReason': recommendReason.trim(),
      'highlights': highlights,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> addProperty(Map<String, dynamic> data) async {
    final document = await properties.add(_withCreatedTimestamp(data));

    return document.id;
  }

  Future<void> updateProperty(String propertyId, Map<String, dynamic> data) {
    return properties.doc(propertyId).update(_withUpdatedTimestamp(data));
  }

  Future<void> updatePropertyCoordinates({
    required String propertyId,
    required double latitude,
    required double longitude,
    required String formattedAddress,
    required String locationType,
  }) {
    return updateProperty(propertyId, {
      'latitude': latitude,
      'longitude': longitude,
      'geocodedAddress': formattedAddress,
      'geocodingLocationType': locationType,
      'geocodedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProperty(String propertyId) {
    return properties.doc(propertyId).delete();
  }

  Future<void> setPropertyActiveStatus(String propertyId, bool active) {
    return updateProperty(propertyId, {'isActive': active});
  }

  // ============================================================
  // CUSTOMER ROOMS
  // ============================================================

  CollectionReference<Map<String, dynamic>> propertyRooms(String propertyId) {
    return properties.doc(propertyId).collection('rooms');
  }

  String newPropertyRoomId(String propertyId) {
    return propertyRooms(propertyId).doc().id;
  }

  Future<void> addPropertyRoom({
    required String propertyId,
    required String roomId,
    required Map<String, dynamic> data,
  }) {
    return propertyRooms(propertyId)
        .doc(roomId)
        .set(_withCreatedTimestamp(data));
  }

  Stream<List<Room>> getRooms(String propertyId) {
    return propertyRooms(propertyId).snapshots().map(
      (snapshot) =>
          snapshot.docs.map(Room.fromFirestore).toList(growable: false),
    );
  }

  // ============================================================
  // ADMIN - ALL PROPERTY ROOMS
  // ============================================================

  Stream<List<Map<String, dynamic>>> watchRooms() {
    return _firestore.collectionGroup('rooms').snapshots().map((snapshot) {
      return snapshot.docs
          .map((document) {
            final propertyDocument = document.reference.parent.parent;

            return <String, dynamic>{
              ...document.data(),
              'id': document.id,
              'propertyId': propertyDocument?.id ?? '',
            };
          })
          .toList(growable: false);
    });
  }

  Stream<List<Map<String, dynamic>>> watchRoomsByProperty(String propertyId) {
    return propertyRooms(propertyId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((document) {
            return <String, dynamic>{
              ...document.data(),
              'id': document.id,
              'propertyId': propertyId,
            };
          })
          .toList(growable: false);
    });
  }

  Future<void> updatePropertyRoom({
    required String propertyId,
    required String roomId,
    required Map<String, dynamic> data,
  }) {
    return propertyRooms(propertyId)
        .doc(roomId)
        .update(_withUpdatedTimestamp(data));
  }

  Future<void> setRoomSaleStatus(
    String roomId,
    bool isOnSale, {
    String? propertyId,
  }) async {
    if (propertyId != null && propertyId.isNotEmpty) {
      await updatePropertyRoom(
        propertyId: propertyId,
        roomId: roomId,
        data: {'isOnSale': isOnSale},
      );

      return;
    }

    // Hỗ trợ collection rooms cũ nếu còn dùng.
    final oldRoom = await rooms.doc(roomId).get();

    if (oldRoom.exists) {
      await rooms
          .doc(roomId)
          .update(_withUpdatedTimestamp({'isOnSale': isOnSale}));
    }
  }

  Future<void> updateRoomPrice({
    required String propertyId,
    required String roomId,
    required int price,
  }) {
    return updatePropertyRoom(
      propertyId: propertyId,
      roomId: roomId,
      data: {'pricePerNight': price},
    );
  }

  Future<void> updateRoomInventory({
    required String propertyId,
    required String roomId,
    required int availableCount,
  }) {
    return updatePropertyRoom(
      propertyId: propertyId,
      roomId: roomId,
      data: {'availableCount': availableCount},
    );
  }

  Future<void> deletePropertyRoom({
    required String propertyId,
    required String roomId,
  }) {
    return propertyRooms(propertyId).doc(roomId).delete();
  }

  // ============================================================
  // OLD ADMIN ROOMS
  // ============================================================

  Future<List<Map<String, dynamic>>> getAllRooms() async {
    return _documentsToMaps(await rooms.get());
  }

  Future<Map<String, dynamic>?> getRoom(String roomId) async {
    final snapshot = await rooms.doc(roomId).get();

    if (!snapshot.exists) {
      return null;
    }

    return {...snapshot.data()!, 'id': snapshot.id};
  }

  Future<String> addRoom(Map<String, dynamic> data) async {
    final document = await rooms.add(_withCreatedTimestamp(data));

    return document.id;
  }

  Future<void> updateRoom(String roomId, Map<String, dynamic> data) {
    return rooms.doc(roomId).update(_withUpdatedTimestamp(data));
  }

  Future<void> deleteRoom(String roomId) {
    return rooms.doc(roomId).delete();
  }

  // ============================================================
  // HOTELS - LEGACY
  // ============================================================

  Stream<List<Map<String, dynamic>>> watchHotels() {
    return hotels.snapshots().map(_documentsToMaps);
  }

  Future<List<Map<String, dynamic>>> getHotels() async {
    return _documentsToMaps(await hotels.get());
  }

  Future<String> addHotel(Map<String, dynamic> data) async {
    final document = await hotels.add(_withCreatedTimestamp(data));

    return document.id;
  }

  Future<void> updateHotel(String hotelId, Map<String, dynamic> data) {
    return hotels.doc(hotelId).update(_withUpdatedTimestamp(data));
  }

  Future<void> deleteHotel(String hotelId) {
    return hotels.doc(hotelId).delete();
  }

  // ============================================================
  // BOOKINGS
  // ============================================================

  Stream<List<Map<String, dynamic>>> watchBookings() {
    return bookings.snapshots().map(_documentsToMaps);
  }

  Stream<List<Map<String, dynamic>>> watchBookingsByProperty(
    String propertyId,
  ) {
    return bookings
        .where('propertyId', isEqualTo: propertyId)
        .snapshots()
        .map(_documentsToMaps);
  }

  Stream<List<Map<String, dynamic>>> watchStaffByProperty(String propertyId) {
    return users
        .where('propertyId', isEqualTo: propertyId)
        .where('isStaff', isEqualTo: true)
        .snapshots()
        .map(_documentsToMaps);
  }

  /// Returns the paid-booking totals that the currently signed-in user is
  /// allowed to read. Owners must supply their property ID so the query stays
  /// within the scope enforced by Firestore rules.
  Future<RevenueReport> getRevenueReport({
    String? propertyId,
    RevenuePeriod period = RevenuePeriod.month,
    DateTime? now,
  }) async {
    final scopedPropertyId = propertyId?.trim();
    if (scopedPropertyId != null && scopedPropertyId.isEmpty) {
      throw ArgumentError.value(propertyId, 'propertyId', 'must not be empty');
    }

    if (scopedPropertyId != null) {
      final bookingFuture = bookings
          .where('propertyId', isEqualTo: scopedPropertyId)
          .get();
      final propertyFuture = properties.doc(scopedPropertyId).get();
      final bookingSnapshot = await bookingFuture;
      final propertySnapshot = await propertyFuture;
      final scopedProperties = propertySnapshot.exists
          ? [
              {
                ...?propertySnapshot.data(),
                'id': propertySnapshot.id,
              },
            ]
          : const <Map<String, dynamic>>[];

      return createRevenueReport(
        properties: scopedProperties,
        bookings: _documentsToMaps(bookingSnapshot),
        period: period,
        now: now,
      );
    }

    final bookingFuture = bookings.get();
    final propertyFuture = properties.get();
    final bookingSnapshot = await bookingFuture;
    final propertySnapshot = await propertyFuture;
    return createRevenueReport(
      properties: _documentsToMaps(propertySnapshot),
      bookings: _documentsToMaps(bookingSnapshot),
      period: period,
      now: now,
    );
  }

  Future<String> addBooking(Map<String, dynamic> data) async {
    final document = await bookings.add(_withCreatedTimestamp(data));

    return document.id;
  }

  Future<void> updateBooking(String bookingId, Map<String, dynamic> data) {
    return bookings.doc(bookingId).update(_withUpdatedTimestamp(data));
  }

  Future<void> deleteBooking(String bookingId) {
    return bookings.doc(bookingId).delete();
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) {
    return updateBooking(bookingId, {'status': status});
  }

  Future<void> updatePaymentStatus({
    required String bookingId,
    required String paymentStatus,
  }) {
    return updateBooking(bookingId, {'paymentStatus': paymentStatus});
  }

  // ============================================================
  // CUSTOMER BOOKINGS
  // ============================================================

  Stream<List<Booking>> getBookingsForUser(String userId, {String? userEmail}) {
    final userIds = <String>{userId};

    if (userEmail != null && userEmail.trim().isNotEmpty) {
      final email = userEmail.trim().toLowerCase();

      userIds.add(email);

      if (email == 'customer@luxestay.vn') {
        userIds.add('demo-customer');
      }
    }

    final query = userIds.length == 1
        ? bookings.where('userId', isEqualTo: userIds.first)
        : bookings.where('userId', whereIn: userIds.toList());

    return query.snapshots().map((snapshot) {
      final result = <Booking>[];

      for (final document in snapshot.docs) {
        try {
          result.add(Booking.fromFirestore(document));
        } catch (_) {
          // Bỏ qua booking lỗi dữ liệu.
        }
      }

      return result;
    });
  }

  // ============================================================
  // USERS
  // ============================================================

  Stream<List<Map<String, dynamic>>> watchUsers() {
    return users.snapshots().map(_documentsToMaps);
  }

  Future<void> setUser(String userId, Map<String, dynamic> data) {
    return users
        .doc(userId)
        .set(_withUpdatedTimestamp(data), SetOptions(merge: true));
  }

  // ============================================================
  // FAVORITES
  // ============================================================

  Future<void> addFavorite({
    required String userId,
    required String propertyId,
  }) {
    return users.doc(userId).collection('favorites').doc(propertyId).set({
      'propertyId': propertyId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFavorite({
    required String userId,
    required String propertyId,
  }) {
    return users.doc(userId).collection('favorites').doc(propertyId).delete();
  }

  Stream<Set<String>> getFavoriteIds(String userId) {
    return users
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((document) => document.id).toSet(),
        );
  }

  Future<bool> isFavorite({
    required String userId,
    required String propertyId,
  }) async {
    final snapshot = await users
        .doc(userId)
        .collection('favorites')
        .doc(propertyId)
        .get();

    return snapshot.exists;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  List<Map<String, dynamic>> _documentsToMaps(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map((document) => {...document.data(), 'id': document.id})
        .toList(growable: false);
  }

  Map<String, dynamic> _withCreatedTimestamp(Map<String, dynamic> data) {
    return {
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _withUpdatedTimestamp(Map<String, dynamic> data) {
    return {...data, 'updatedAt': FieldValue.serverTimestamp()};
  }
}

enum RevenuePeriod {
  week('Tuần '),
  month('Tháng '),
  year('Năm ');

  const RevenuePeriod(this.label);

  final String label;
}

class RevenueReport {
  const RevenueReport({
    required this.period,
    required this.totalRevenue,
    required this.paidBookingCount,
    required this.properties,
    required this.trend,
  });

  final RevenuePeriod period;
  final int totalRevenue;
  final int paidBookingCount;
  final List<RevenuePropertyReport> properties;
  final List<RevenueReportTrendPoint> trend;
}

class RevenuePropertyReport {
  const RevenuePropertyReport({
    required this.propertyId,
    required this.propertyName,
    required this.revenue,
    required this.paidBookingCount,
  });

  final String propertyId;
  final String propertyName;
  final int revenue;
  final int paidBookingCount;
}

class RevenueReportTrendPoint {
  const RevenueReportTrendPoint({
    required this.label,
    required this.revenue,
  });

  final String label;
  final int revenue;
}

/// Builds the revenue payload shared by the admin and owner dashboards.
/// Only paid bookings created in the selected period contribute to revenue.
RevenueReport createRevenueReport({
  required Iterable<Map<String, dynamic>> properties,
  required Iterable<Map<String, dynamic>> bookings,
  RevenuePeriod period = RevenuePeriod.month,
  DateTime? now,
}) {
  final reportDate = now ?? DateTime.now();
  final range = _revenueRange(period, reportDate);
  final propertyNames = <String, String>{
    for (final property in properties)
      if (property['id']?.toString().isNotEmpty ?? false)
        property['id'].toString(): property['name']?.toString() ?? 'Khách sạn',
  };
  final totals = <String, _RevenueTotal>{};
  final trendRevenue = List<int>.filled(
    _revenueTrendLabels(period, reportDate).length,
    0,
  );

  for (final booking in bookings) {
    if (booking['paymentStatus']?.toString().toLowerCase() != 'paid') {
      continue;
    }

    final propertyId = booking['propertyId']?.toString() ?? '';
    if (!propertyNames.containsKey(propertyId)) continue;
    final bookingDate =
        _readRevenueDate(booking['createdAt']) ??
        _readRevenueDate(booking['checkIn']);
    if (bookingDate == null ||
        bookingDate.isBefore(range.start) ||
        !bookingDate.isBefore(range.end)) {
      continue;
    }

    final total = totals.putIfAbsent(propertyId, _RevenueTotal.new);
    final revenue = _revenueAmount(booking['totalPrice']);
    total.revenue += revenue;
    total.paidBookingCount += 1;
    final trendIndex = _revenueTrendIndex(
      period: period,
      bookingDate: bookingDate,
      rangeStart: range.start,
    );
    if (trendIndex >= 0 && trendIndex < trendRevenue.length) {
      trendRevenue[trendIndex] += revenue;
    }
  }

  final reports = propertyNames.entries
      .map(
        (property) {
          final total = totals[property.key] ?? _RevenueTotal();
          return RevenuePropertyReport(
            propertyId: property.key,
            propertyName: property.value,
            revenue: total.revenue,
            paidBookingCount: total.paidBookingCount,
          );
        },
      )
      .toList(growable: false)
    ..sort((a, b) => b.revenue.compareTo(a.revenue));
  final labels = _revenueTrendLabels(period, reportDate);

  return RevenueReport(
    period: period,
    totalRevenue: reports.fold<int>(
      0,
      (total, report) => total + report.revenue,
    ),
    paidBookingCount: reports.fold<int>(
      0,
      (total, report) => total + report.paidBookingCount,
    ),
    properties: reports,
    trend: List.generate(
      labels.length,
      (index) => RevenueReportTrendPoint(
        label: labels[index],
        revenue: trendRevenue[index],
      ),
      growable: false,
    ),
  );
}

class _RevenueTotal {
  int revenue = 0;
  int paidBookingCount = 0;
}

int _revenueAmount(dynamic value) {
  if (value is num) return value.round();
  return num.tryParse(value?.toString() ?? '')?.round() ?? 0;
}

({DateTime start, DateTime end}) _revenueRange(
  RevenuePeriod period,
  DateTime now,
) {
  final today = DateTime(now.year, now.month, now.day);
  return switch (period) {
    RevenuePeriod.week => (
      start: today.subtract(Duration(days: today.weekday - DateTime.monday)),
      end: today
          .subtract(Duration(days: today.weekday - DateTime.monday))
          .add(const Duration(days: 7)),
    ),
    RevenuePeriod.month => (
      start: DateTime(now.year, now.month),
      end: DateTime(now.year, now.month + 1),
    ),
    RevenuePeriod.year => (
      start: DateTime(now.year),
      end: DateTime(now.year + 1),
    ),
  };
}

List<String> _revenueTrendLabels(RevenuePeriod period, DateTime now) {
  return switch (period) {
    RevenuePeriod.week => const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'],
    RevenuePeriod.month => List.generate(
      (DateTime(now.year, now.month + 1, 0).day + 6) ~/ 7,
      (index) {
        final firstDay = index * 7 + 1;
        final lastDay = (firstDay + 6).clamp(
          1,
          DateTime(now.year, now.month + 1, 0).day,
        );
        return '$firstDay-$lastDay';
      },
      growable: false,
    ),
    RevenuePeriod.year => List.generate(
      12,
      (index) => 'T${index + 1}',
      growable: false,
    ),
  };
}

int _revenueTrendIndex({
  required RevenuePeriod period,
  required DateTime bookingDate,
  required DateTime rangeStart,
}) {
  return switch (period) {
    RevenuePeriod.week =>
      DateTime(bookingDate.year, bookingDate.month, bookingDate.day)
          .difference(rangeStart)
          .inDays,
    RevenuePeriod.month => (bookingDate.day - 1) ~/ 7,
    RevenuePeriod.year => bookingDate.month - 1,
  };
}

DateTime? _readRevenueDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}
