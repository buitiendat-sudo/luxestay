
import 'package:cloud_functions/cloud_functions.dart';

import '../models/ai_travel_plan.dart';
import 'firestore_service.dart';

class AiTravelService {
  AiTravelService(this.firestoreService);

  final FirestoreService firestoreService;

  Future<AiTravelPlan> generateTravelPlan({
    required String destination,
    required int days,
    required int guests,
    required int budget,
  }) async {
    final properties =
        await firestoreService.getProperties().first;

    final matchingProperties = properties.where((property) {
      final destinationText = destination.trim().toLowerCase();

      if (destinationText.isEmpty) {
        return true;
      }

      return property.location.toLowerCase().contains(
            destinationText,
          ) ||
          property.name.toLowerCase().contains(
            destinationText,
          );
    }).toList();

    final sourceProperties =
        matchingProperties.isEmpty ? properties : matchingProperties;

    final hotelInventory = <Map<String, dynamic>>[];

    for (var offset = 0; offset < sourceProperties.length; offset += 5) {
      final propertyBatch = sourceProperties.skip(offset).take(5).toList();
      final roomsByProperty = await Future.wait(
        propertyBatch.map(
          (property) => firestoreService.getRooms(property.id).first,
        ),
      );

      for (var index = 0; index < propertyBatch.length; index++) {
        final property = propertyBatch[index];
        for (final room in roomsByProperty[index]) {
          hotelInventory.add({
            'propertyId': property.id,
            'propertyName': property.name,
            'location': property.location,
            'rating': property.rating,
            'reviewCount': property.reviewCount,
            'category': property.category,
            'propertyImage': property.image,
            'propertyAmenities': property.amenities,
            'roomId': room.id,
            'roomName': room.name,
            'area': room.area,
            'bedType': room.bedType,
            'view': room.view,
            'roomImage': room.image,
            'roomAmenities': room.amenities,
            'pricePerNight': room.pricePerNight,
            'availableCount': room.availableCount,
          });
        }
      }
    }

    if (hotelInventory.isEmpty) {
      throw Exception(
        'Không tìm thấy phòng khách sạn phù hợp trong LuxeStay.',
      );
    }

    final functions = FirebaseFunctions.instanceFor(
      region: 'asia-southeast1',
    );
    if (const bool.fromEnvironment('USE_FUNCTIONS_EMULATOR')) {
      functions.useFunctionsEmulator('127.0.0.1', 5001);
    }

    final callable = functions.httpsCallable('generateTravelPlan');
    final response = await callable.call<Map<String, dynamic>>({
      'destination': destination,
      'days': days,
      'guests': guests,
      'budget': budget,
      'hotelInventory': hotelInventory,
    });

    return AiTravelPlan.fromJson(
      Map<String, dynamic>.from(response.data),
    );
  }
}

