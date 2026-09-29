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

  Future<void> addPropertyRoom({
    required String propertyId,
    required Map<String, dynamic> data,
  }) async {
    await propertyRooms(propertyId).add(_withCreatedTimestamp(data));
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

  Future<void> updateUserRole({required String userId, required String role}) {
    return setUser(userId, {'role': role.toUpperCase()});
  }

  Future<void> updateUserStatus({
    required String userId,
    required bool active,
  }) {
    return setUser(userId, {'isActive': active});
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
