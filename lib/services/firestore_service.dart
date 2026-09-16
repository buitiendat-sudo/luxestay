import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/property.dart';
import '../models/room.dart';

/// Injectable gateway for the Firestore collections used by LuxeStay.
/// Documents returned by this service include their Firestore id in [id].
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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

  CollectionReference<Map<String, dynamic>> propertyRooms(String propertyId) =>
      properties.doc(propertyId).collection('rooms');

  Stream<List<Property>> getProperties() => properties
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(Property.fromFirestore)
            .toList(growable: false),
      );

  /// Watches rooms at `properties/{propertyId}/rooms` for a resort.
  Stream<List<Room>> getRooms(String propertyId) => propertyRooms(propertyId)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(Room.fromFirestore)
            .toList(growable: false),
      );

  Stream<List<Map<String, dynamic>>> watchRooms() =>
      rooms.snapshots().map(_documentsToMaps);

  Future<List<Map<String, dynamic>>> getAllRooms() async =>
      _documentsToMaps(await rooms.get());

  Future<Map<String, dynamic>?> getRoom(String roomId) async {
    final snapshot = await rooms.doc(roomId).get();
    if (!snapshot.exists) return null;
    return <String, dynamic>{...snapshot.data()!, 'id': snapshot.id};
  }

  Future<String> addRoom(Map<String, dynamic> data) async {
    final document = await rooms.add(_withCreatedTimestamp(data));
    return document.id;
  }

  Future<void> updateRoom(String roomId, Map<String, dynamic> data) =>
      rooms.doc(roomId).update(_withUpdatedTimestamp(data));

  Future<void> deleteRoom(String roomId) => rooms.doc(roomId).delete();

  /// Opens or closes a room for sale without changing its stock.
  /// No default value is assigned to `availableCount` here.
  Future<void> setRoomSaleStatus(String roomId, bool isOnSale) =>
      updateRoom(roomId, <String, dynamic>{'isOnSale': isOnSale});

  Stream<List<Map<String, dynamic>>> watchHotels() =>
      hotels.snapshots().map(_documentsToMaps);

  Future<List<Map<String, dynamic>>> getHotels() async =>
      _documentsToMaps(await hotels.get());

  Future<String> addHotel(Map<String, dynamic> data) async {
    final document = await hotels.add(_withCreatedTimestamp(data));
    return document.id;
  }

  Future<void> updateHotel(String hotelId, Map<String, dynamic> data) =>
      hotels.doc(hotelId).update(_withUpdatedTimestamp(data));

  Future<void> deleteHotel(String hotelId) => hotels.doc(hotelId).delete();

  Stream<List<Map<String, dynamic>>> watchBookings() =>
      bookings.snapshots().map(_documentsToMaps);

  Future<String> addBooking(Map<String, dynamic> data) async {
    final document = await bookings.add(_withCreatedTimestamp(data));
    return document.id;
  }

  Future<void> updateBooking(String bookingId, Map<String, dynamic> data) =>
      bookings.doc(bookingId).update(_withUpdatedTimestamp(data));

  Future<void> deleteBooking(String bookingId) =>
      bookings.doc(bookingId).delete();

  Stream<List<Map<String, dynamic>>> watchUsers() =>
      users.snapshots().map(_documentsToMaps);

  Future<void> setUser(String userId, Map<String, dynamic> data) =>
      users.doc(userId).set(
            _withUpdatedTimestamp(data),
            SetOptions(merge: true),
          );

  List<Map<String, dynamic>> _documentsToMaps(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) =>
      snapshot.docs
          .map(
            (document) => <String, dynamic>{
              ...document.data(),
              'id': document.id,
            },
          )
          .toList(growable: false);

  Map<String, dynamic> _withCreatedTimestamp(Map<String, dynamic> data) =>
      <String, dynamic>{
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> _withUpdatedTimestamp(Map<String, dynamic> data) =>
      <String, dynamic>{
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
