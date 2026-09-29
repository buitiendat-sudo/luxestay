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
    this.paymentMethod = 'credit_card',
    this.paymentStatus = 'unpaid',
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
  final String paymentMethod;
  final String paymentStatus;

  final String status;
  final DateTime? createdAt;

  factory Booking.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    return Booking(
      id: document.id,
      userId: data['userId']?.toString() ?? '',
      propertyId: data['propertyId']?.toString() ?? '',
      propertyName: data['propertyName']?.toString() ?? '',
      roomId: data['roomId']?.toString() ?? '',
      roomName: data['roomName']?.toString() ?? '',
      checkIn: _readDate(data['checkIn']),
      checkOut: _readDate(data['checkOut']),
      guests: _parseInt(data['guests'], 1),
      rooms: _parseInt(data['rooms'], 1),
      pricePerNight: _parseInt(data['pricePerNight'], 0),
      totalNights: _parseInt(data['totalNights'], 1),
      totalPrice: _parseInt(data['totalPrice'], 0),
      paymentMethod: data['paymentMethod']?.toString() ?? 'credit_card',
      paymentStatus: data['paymentStatus']?.toString() ?? 'unpaid',
      status: data['status']?.toString() ?? 'pending',
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
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'status': status,
      'createdAt': createdAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt!),
    };
  }

  static int _parseInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is num) return value.toInt();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9\-]'), '');
      return int.tryParse(cleaned) ?? defaultValue;
    }
    return defaultValue;
  }

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  static DateTime? _readNullableDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}