
class AiTravelPlan {
  const AiTravelPlan({
    required this.destination,
    required this.summary,
    required this.budget,
    required this.hotels,
    required this.itinerary,
    required this.restaurants,
    required this.places,
  });

  final String destination;
  final String summary;
  final AiBudget budget;
  final List<AiHotelRecommendation> hotels;
  final List<AiDayPlan> itinerary;
  final List<AiRestaurant> restaurants;
  final List<AiPlace> places;

  factory AiTravelPlan.fromJson(Map<String, dynamic> json) {
    return AiTravelPlan(
      destination: json['destination'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      budget: AiBudget.fromJson(
        Map<String, dynamic>.from(
          json['budget'] as Map? ?? const {},
        ),
      ),
      hotels: (json['hotels'] as List? ?? const [])
          .map(
            (item) => AiHotelRecommendation.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      itinerary: (json['itinerary'] as List? ?? const [])
          .map(
            (item) => AiDayPlan.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      restaurants: (json['restaurants'] as List? ?? const [])
          .map(
            (item) => AiRestaurant.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      places: (json['places'] as List? ?? const [])
          .map(
            (item) => AiPlace.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class AiBudget {
  const AiBudget({
    required this.hotel,
    required this.food,
    required this.transport,
    required this.activities,
    required this.other,
    required this.total,
  });

  final int hotel;
  final int food;
  final int transport;
  final int activities;
  final int other;
  final int total;

  factory AiBudget.fromJson(Map<String, dynamic> json) {
    int value(String key) => (json[key] as num?)?.toInt() ?? 0;

    return AiBudget(
      hotel: value('hotel'),
      food: value('food'),
      transport: value('transport'),
      activities: value('activities'),
      other: value('other'),
      total: value('total'),
    );
  }
}

class AiHotelRecommendation {
  const AiHotelRecommendation({
    required this.propertyId,
    required this.roomId,
    required this.reason,
    required this.estimatedTotal,
  });

  final String propertyId;
  final String roomId;
  final String reason;
  final int estimatedTotal;

  factory AiHotelRecommendation.fromJson(Map<String, dynamic> json) {
    return AiHotelRecommendation(
      propertyId: json['propertyId'] as String? ?? '',
      roomId: json['roomId'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      estimatedTotal:
          (json['estimatedTotal'] as num?)?.toInt() ?? 0,
    );
  }
}

class AiDayPlan {
  const AiDayPlan({
    required this.day,
    required this.title,
    required this.activities,
    required this.estimatedCost,
  });

  final int day;
  final String title;
  final List<String> activities;
  final int estimatedCost;

  factory AiDayPlan.fromJson(Map<String, dynamic> json) {
    return AiDayPlan(
      day: (json['day'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? '',
      activities: List<String>.from(
        json['activities'] as List? ?? const [],
      ),
      estimatedCost:
          (json['estimatedCost'] as num?)?.toInt() ?? 0,
    );
  }
}

class AiRestaurant {
  const AiRestaurant({
    required this.name,
    required this.description,
    required this.estimatedCost,
  });

  final String name;
  final String description;
  final int estimatedCost;

  factory AiRestaurant.fromJson(Map<String, dynamic> json) {
    return AiRestaurant(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      estimatedCost:
          (json['estimatedCost'] as num?)?.toInt() ?? 0,
    );
  }
}

class AiPlace {
  const AiPlace({
    required this.name,
    required this.description,
    required this.estimatedCost,
  });

  final String name;
  final String description;
  final int estimatedCost;

  factory AiPlace.fromJson(Map<String, dynamic> json) {
    return AiPlace(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      estimatedCost:
          (json['estimatedCost'] as num?)?.toInt() ?? 0,
    );
  }
}

