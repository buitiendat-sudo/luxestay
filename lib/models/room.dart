import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  const Room({
    required this.id,
    required this.name,
    required this.area,
    required this.bedType,
    required this.pricePerNight,
    required this.view,
    required this.amenities,
    required this.availableCount,
  });

  final String id;
  final String name;
  final int area;
  final String bedType;
  final int pricePerNight;
  final String view;
  final List<String> amenities;
  final int availableCount;

  factory Room.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    return Room(
      id: document.id,
      name: data['name'] as String? ?? '',
      area: ((data['area'] ?? data['size']) as num?)?.toInt() ?? 0,
      bedType: (data['bedType'] ?? data['bed']) as String? ?? '',
      pricePerNight:
          ((data['pricePerNight'] ?? data['price']) as num?)?.toInt() ?? 0,
      view: data['view'] as String? ?? '',
      amenities: List<String>.from(data['amenities'] as List? ?? const []),
      availableCount: (data['availableCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name,
        'area': area,
        'bedType': bedType,
        'pricePerNight': pricePerNight,
        'view': view,
        'amenities': amenities,
        'availableCount': availableCount,
      };
}
