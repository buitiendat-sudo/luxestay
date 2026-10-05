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
        Map<String, dynamic>.from(json['budget'] as Map? ?? const {}),
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
            (item) =>
                AiDayPlan.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      restaurants: (json['restaurants'] as List? ?? const [])
          .map(
            (item) =>
                AiRestaurant.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      places: (json['places'] as List? ?? const [])
          .map(
            (item) => AiPlace.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'destination': destination,
      'summary': summary,
      'budget': budget.toJson(),
      'hotels': hotels.map((e) => e.toJson()).toList(),
      'itinerary': itinerary.map((e) => e.toJson()).toList(),
      'restaurants': restaurants.map((e) => e.toJson()).toList(),
      'places': places.map((e) => e.toJson()).toList(),
    };
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

  Map<String, dynamic> toJson() {
    return {
      'hotel': hotel,
      'food': food,
      'transport': transport,
      'activities': activities,
      'other': other,
      'total': total,
    };
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
      estimatedTotal: (json['estimatedTotal'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'propertyId': propertyId,
      'roomId': roomId,
      'reason': reason,
      'estimatedTotal': estimatedTotal,
    };
  }
}

class AiDayPlan {
  const AiDayPlan({
    required this.day,
    required this.title,
    required this.activities,
    required this.estimatedCost,
    required this.schedule,
  });

  final int day;
  final String title;

  // Giữ lại để tương thích với code cũ.
  final List<String> activities;

  final int estimatedCost;

  // Bảng lịch trình chi tiết.
  final List<AiScheduleItem> schedule;

  factory AiDayPlan.fromJson(Map<String, dynamic> json) {
    return AiDayPlan(
      day: (json['day'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? '',
      activities: List<String>.from(json['activities'] as List? ?? const []),
      estimatedCost: (json['estimatedCost'] as num?)?.toInt() ?? 0,
      schedule: (json['schedule'] as List? ?? const [])
          .map(
            (item) =>
                AiScheduleItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'title': title,
      'activities': activities,
      'estimatedCost': estimatedCost,
      'schedule': schedule.map((e) => e.toJson()).toList(),
    };
  }
}

class AiScheduleItem {
  const AiScheduleItem({
    required this.time,
    required this.activity,
    required this.place,
    required this.transport,
    required this.cost,
    required this.note,
  });

  final String time;
  final String activity;
  final String place;
  final String transport;
  final int cost;
  final String note;

  factory AiScheduleItem.fromJson(Map<String, dynamic> json) {
    return AiScheduleItem(
      time: json['time'] as String? ?? '',
      activity: json['activity'] as String? ?? '',
      place: json['place'] as String? ?? '',
      transport: json['transport'] as String? ?? '',
      cost: (json['cost'] as num?)?.toInt() ?? 0,
      note: json['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'activity': activity,
      'place': place,
      'transport': transport,
      'cost': cost,
      'note': note,
    };
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
      estimatedCost: (json['estimatedCost'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'estimatedCost': estimatedCost,
    };
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
      estimatedCost: (json['estimatedCost'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'estimatedCost': estimatedCost,
    };
  }
}
