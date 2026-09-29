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
    required this.category,
    this.description = '',
    this.address = '',
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String location;
  final String image;
  final double rating;
  final int reviewCount;
  final int pricePerNight;
  final List<String> amenities;
  final String category;
  final String description;
  final String address;
  final double? latitude;
  final double? longitude;

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
      amenities: List<String>.from(
        data['amenities'] as List? ?? const [],
      ),
      category: data['category'] as String? ?? '',
      description: data['description'] as String? ?? '',
      address: data['address'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
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
        'category': category,
        'description': description,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };
}