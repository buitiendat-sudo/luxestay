import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  const Booking({
    required this.id,
    required this.userId,
    required this.propertyId,
    required this.propertyName,
    required this.roomId,
    required this.roomName,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.rooms,
    required this.pricePerNight,
    required this.totalNights,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String propertyId;
  final String propertyName;
  final String roomId;
  final String roomName;

  final DateTime checkIn;
  final DateTime checkOut;

  final int guests;
  final int rooms;

  final int pricePerNight;
  final int totalNights;
  final int totalPrice;

  final String status;
  final DateTime? createdAt;

  factory Booking.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    return Booking(
      id: document.id,
      userId: data['userId'] as String? ?? '',
      propertyId: data['propertyId'] as String? ?? '',
      propertyName: data['propertyName'] as String? ?? '',
      roomId: data['roomId'] as String? ?? '',
      roomName: data['roomName'] as String? ?? '',
      checkIn: _readDate(data['checkIn']),
      checkOut: _readDate(data['checkOut']),
      guests: (data['guests'] as num?)?.toInt() ?? 1,
      rooms: (data['rooms'] as num?)?.toInt() ?? 1,
      pricePerNight:
          (data['pricePerNight'] as num?)?.toInt() ?? 0,
      totalNights:
          (data['totalNights'] as num?)?.toInt() ?? 1,
      totalPrice:
          (data['totalPrice'] as num?)?.toInt() ?? 0,
      status: data['status'] as String? ?? 'pending',
      createdAt: _readNullableDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'roomId': roomId,
      'roomName': roomName,
      'checkIn': Timestamp.fromDate(checkIn),
      'checkOut': Timestamp.fromDate(checkOut),
      'guests': guests,
      'rooms': rooms,
      'pricePerNight': pricePerNight,
      'totalNights': totalNights,
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return DateTime.now();
  }

  static DateTime? _readNullableDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}