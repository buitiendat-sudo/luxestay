import 'package:cloud_firestore/cloud_firestore.dart';

class Property {
  const Property({
    required this.id,
    required this.name,
    required this.location,
    required this.image,
    required this.rating,
    required this.reviewCount,
    required this.pricePerNight,
    required this.amenities,
  });

  final String id;
  final String name;
  final String location;
  final String image;
  final double rating;
  final int reviewCount;
  final int pricePerNight;
  final List<String> amenities;

  factory Property.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    return Property(
      id: document.id,
      name: data['name'] as String? ?? '',
      location: data['location'] as String? ?? '',
      image: data['image'] as String? ?? '',
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      pricePerNight: (data['pricePerNight'] as num?)?.toInt() ?? 0,
      amenities: List<String>.from(data['amenities'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name,
        'location': location,
        'image': image,
        'rating': rating,
        'reviewCount': reviewCount,
        'pricePerNight': pricePerNight,
        'amenities': amenities,
      };
}
