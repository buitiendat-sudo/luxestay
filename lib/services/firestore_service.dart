import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/property.dart';
import '../models/room.dart';
import '../models/booking.dart';

/// Gateway làm việc với Firestore của LuxeStay.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  CollectionReference<Map<String, dynamic>> get rooms =>
      _firestore.collection('rooms');

  CollectionReference<Map<String, dynamic>> get hotels =>
      _firestore.collection('hotels');

  CollectionReference<Map<String, dynamic>> get bookings =>
      _firestore.collection('bookings');

  CollectionReference<Map<String, dynamic>> get users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get properties =>
      _firestore.collection('properties');

  // ============================================================
  // PROPERTIES
  // ============================================================

  Stream<List<Property>> getProperties() {
    return properties.snapshots().map(
          (snapshot) => snapshot.docs
              .map(Property.fromFirestore)
              .toList(growable: false),
        );
  }

  // ============================================================
  // ROOMS - PROPERTY
  // ============================================================

  CollectionReference<Map<String, dynamic>> propertyRooms(
    String propertyId,
  ) {
    return properties.doc(propertyId).collection('rooms');
  }

  Stream<List<Room>> getRooms(String propertyId) {
    return propertyRooms(propertyId).snapshots().map(
          (snapshot) => snapshot.docs
              .map(Room.fromFirestore)
              .toList(growable: false),
        );
  }

  // ============================================================
  // ROOMS - ADMIN
  // ============================================================

  Stream<List<Map<String, dynamic>>> watchRooms() {
    return rooms.snapshots().map(_documentsToMaps);
  }

  Future<List<Map<String, dynamic>>> getAllRooms() async {
    return _documentsToMaps(await rooms.get());
  }

  Future<Map<String, dynamic>?> getRoom(String roomId) async {
    final snapshot = await rooms.doc(roomId).get();

    if (!snapshot.exists) {
      return null;
    }

    return <String, dynamic>{
      ...snapshot.data()!,
      'id': snapshot.id,
    };
  }

  Future<String> addRoom(Map<String, dynamic> data) async {
    final document = await rooms.add(
      _withCreatedTimestamp(data),
    );

    return document.id;
  }

  Future<void> updateRoom(
    String roomId,
    Map<String, dynamic> data,
  ) {
    return rooms.doc(roomId).update(
          _withUpdatedTimestamp(data),
        );
  }

  Future<void> deleteRoom(String roomId) {
    return rooms.doc(roomId).delete();
  }

  Future<void> setRoomSaleStatus(
    String roomId,
    bool isOnSale,
  ) {
    return updateRoom(
      roomId,
      <String, dynamic>{
        'isOnSale': isOnSale,
      },
    );
  }

  // ============================================================
  // HOTELS
  // ============================================================

  Stream<List<Map<String, dynamic>>> watchHotels() {
    return hotels.snapshots().map(_documentsToMaps);
  }

  Future<List<Map<String, dynamic>>> getHotels() async {
    return _documentsToMaps(await hotels.get());
  }

  Future<String> addHotel(Map<String, dynamic> data) async {
    final document = await hotels.add(
      _withCreatedTimestamp(data),
    );

    return document.id;
  }

  Future<void> updateHotel(
    String hotelId,
    Map<String, dynamic> data,
  ) {
    return hotels.doc(hotelId).update(
          _withUpdatedTimestamp(data),
        );
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

  Future<String> addBooking(Map<String, dynamic> data) async {
    final document = await bookings.add(
      _withCreatedTimestamp(data),
    );

    return document.id;
  }

  Future<void> updateBooking(
    String bookingId,
    Map<String, dynamic> data,
  ) {
    return bookings.doc(bookingId).update(
          _withUpdatedTimestamp(data),
        );
  }

  Future<void> deleteBooking(String bookingId) {
    return bookings.doc(bookingId).delete();
  }

  // ============================================================
  // BOOKINGS - CUSTOMER
  // ============================================================

  Stream<List<Booking>> getBookingsForUser(
    String userId, {
    String? userEmail,
  }) {
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

    return query.snapshots().map(
      (snapshot) {
        final list = <Booking>[];
        for (final doc in snapshot.docs) {
          try {
            list.add(Booking.fromFirestore(doc));
          } catch (_) {
            // Skip invalid documents so other bookings still display properly
          }
        }
        return list;
      },
    );
  }

  // ============================================================
  // USERS
  // ============================================================

  Stream<List<Map<String, dynamic>>> watchUsers() {
    return users.snapshots().map(_documentsToMaps);
  }

  Future<void> setUser(
    String userId,
    Map<String, dynamic> data,
  ) {
    return users.doc(userId).set(
          _withUpdatedTimestamp(data),
          SetOptions(merge: true),
        );
  }

  // ============================================================
  // FAVORITES ❤️
  // ============================================================

  /// Lưu một resort vào danh sách yêu thích của user.
  ///
  /// Firestore:
  ///
  /// users/{userId}/favorites/{propertyId}
  Future<void> addFavorite({
    required String userId,
    required String propertyId,
  }) async {
    await users
        .doc(userId)
        .collection('favorites')
        .doc(propertyId)
        .set({
      'propertyId': propertyId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Xóa resort khỏi danh sách yêu thích.
  Future<void> removeFavorite({
    required String userId,
    required String propertyId,
  }) async {
    await users
        .doc(userId)
        .collection('favorites')
        .doc(propertyId)
        .delete();
  }

  /// Theo dõi realtime danh sách ID resort yêu thích.
  Stream<Set<String>> getFavoriteIds(String userId) {
    return users
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((document) => document.id)
              .toSet(),
        );
  }

  /// Kiểm tra một resort có được yêu thích hay không.
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
        .map(
          (document) => <String, dynamic>{
            ...document.data(),
            'id': document.id,
          },
        )
        .toList(growable: false);
  }

  Map<String, dynamic> _withCreatedTimestamp(
    Map<String, dynamic> data,
  ) {
    return <String, dynamic>{
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _withUpdatedTimestamp(
    Map<String, dynamic> data,
  ) {
    return <String, dynamic>{
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}