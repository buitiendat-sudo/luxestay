import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../models/ai_travel_plan.dart';
import 'firestore_service.dart';

class AiTravelService {
  AiTravelService(this.firestoreService);

  final FirestoreService firestoreService;

  // ============================================================
  // CREATE TRAVEL PLAN
  // ============================================================

  Future<AiTravelPlan> generateTravelPlan({
    required String destination,
    required int days,
    required int guests,
    required int budget,
  }) async {
    final hotelInventory =
        await _loadHotelInventory(
      destination,
    );

    if (hotelInventory.isEmpty) {
      throw Exception(
        'Không tìm thấy phòng khách sạn phù hợp trong LuxeStay.',
      );
    }

    try {
      final prompt = _buildGeneratePrompt(
        destination: destination,
        days: days,
        guests: guests,
        budget: budget,
        hotelInventory: hotelInventory,
      );

      return await _generateFromGemini(prompt);
    } catch (error) {
      // ========================================================
      // DEMO FALLBACK
      // Nếu Gemini hết quota / lỗi API thì dùng kế hoạch demo.
      // ========================================================

      if (_isQuotaOrApiError(error)) {
        return _buildDemoPlan(
          destination: destination,
          days: days,
          guests: guests,
          budget: budget,
          hotelInventory: hotelInventory,
        );
      }

      rethrow;
    }
  }

  // ============================================================
  // REVISE TRAVEL PLAN
  // ============================================================

  Future<AiTravelPlan> reviseTravelPlan({
    required AiTravelPlan currentPlan,
    required String userRequest,
  }) async {
    try {
      final prompt = _buildRevisionPrompt(
        currentPlan: currentPlan,
        userRequest: userRequest,
      );

      return await _generateFromGemini(prompt);
    } catch (error) {
      // ========================================================
      // DEMO FALLBACK CHO CHATBOT
      // ========================================================

      if (_isQuotaOrApiError(error)) {
        return _reviseDemoPlan(
          currentPlan: currentPlan,
          userRequest: userRequest,
        );
      }

      rethrow;
    }
  }

  // ============================================================
  // LOAD HOTEL INVENTORY FROM FIRESTORE
  // ============================================================

  Future<List<Map<String, dynamic>>>
      _loadHotelInventory(
    String destination,
  ) async {
    final properties =
        await firestoreService
            .getProperties()
            .first;

    final destinationText =
        destination.trim().toLowerCase();

    final matchingProperties =
        properties.where((property) {
      if (destinationText.isEmpty) {
        return true;
      }

      return property.location
              .toLowerCase()
              .contains(destinationText) ||
          property.name
              .toLowerCase()
              .contains(destinationText);
    }).toList();

    final sourceProperties = matchingProperties;

    final inventory =
        <Map<String, dynamic>>[];

    for (
      var offset = 0;
      offset < sourceProperties.length;
      offset += 5
    ) {
      final propertyBatch =
          sourceProperties
              .skip(offset)
              .take(5)
              .toList();

      final roomsByProperty =
          await Future.wait(
        propertyBatch.map(
          (property) =>
              firestoreService
                  .getRooms(property.id)
                  .first,
        ),
      );

      for (
        var index = 0;
        index < propertyBatch.length;
        index++
      ) {
        final property =
            propertyBatch[index];

        for (
          final room
              in roomsByProperty[index]
        ) {
          if (room.availableCount <= 0) {
            continue;
          }

          inventory.add({
            'propertyId':
                property.id,
            'propertyName':
                property.name,
            'location':
                property.location,
            'rating':
                property.rating,
            'reviewCount':
                property.reviewCount,
            'category':
                property.category,
            'propertyImage':
                property.image,
            'propertyAmenities':
                property.amenities,

            'roomId':
                room.id,
            'roomName':
                room.name,
            'area':
                room.area,
            'bedType':
                room.bedType,
            'view':
                room.view,
            'roomImage':
                room.image,
            'roomAmenities':
                room.amenities,
            'pricePerNight':
                room.pricePerNight,
            'availableCount':
                room.availableCount,
          });
        }
      }
    }

    return inventory;
  }

  // ============================================================
  // GENERATE PROMPT
  // ============================================================

  String _buildGeneratePrompt({
    required String destination,
    required int days,
    required int guests,
    required int budget,
    required List<Map<String, dynamic>>
        hotelInventory,
  }) {
    return '''
Bạn là AI Travel Planner của ứng dụng LuxeStay.

Thông tin chuyến đi:

Điểm đến: $destination
Số ngày: $days
Số khách: $guests
Ngân sách: $budget VND

Hãy tạo kế hoạch du lịch chi tiết.

YÊU CẦU:

- Có đủ $days ngày.
- Mỗi ngày có lịch trình chi tiết.
- Có thời gian.
- Có hoạt động.
- Có địa điểm.
- Có phương tiện.
- Có chi phí.
- Có ghi chú.
- Có nhà hàng.
- Có địa điểm tham quan.
- Có phân bổ ngân sách.
- BẮT BUỘC đề xuất khách sạn/phòng từ dữ liệu LuxeStay.
- Chỉ sử dụng propertyId và roomId tồn tại trong dữ liệu.
- Không tự tạo propertyId.
- Không tự tạo roomId.
- Chỉ sử dụng phòng có availableCount > 0.
- Ưu tiên phòng phù hợp ngân sách.

DỮ LIỆU KHÁCH SẠN LUXESTAY:

${jsonEncode(
      hotelInventory.take(20).toList(),
    )}

TRẢ VỀ JSON THUẦN TÚY:

{
  "destination": "",
  "summary": "",

  "budget": {
    "hotel": 0,
    "food": 0,
    "transport": 0,
    "activities": 0,
    "other": 0,
    "total": 0
  },

  "hotels": [
    {
      "propertyId": "",
      "roomId": "",
      "reason": "",
      "estimatedTotal": 0
    }
  ],

  "itinerary": [
    {
      "day": 1,
      "title": "",
      "activities": [],
      "estimatedCost": 0,

      "schedule": [
        {
          "time": "",
          "activity": "",
          "place": "",
          "transport": "",
          "cost": 0,
          "note": ""
        }
      ]
    }
  ],

  "restaurants": [
    {
      "name": "",
      "description": "",
      "estimatedCost": 0
    }
  ],

  "places": [
    {
      "name": "",
      "description": "",
      "estimatedCost": 0
    }
  ]
}
''';
  }

  // ============================================================
  // REVISION PROMPT
  // ============================================================

  String _buildRevisionPrompt({
    required AiTravelPlan currentPlan,
    required String userRequest,
  }) {
    return '''
Bạn là trợ lý AI của LuxeStay.

KẾ HOẠCH HIỆN TẠI:

${jsonEncode(currentPlan.toJson())}

YÊU CẦU CỦA NGƯỜI DÙNG:

$userRequest

Hãy chỉnh sửa kế hoạch theo yêu cầu.

QUY TẮC:

1. Chỉ thay đổi phần người dùng yêu cầu.
2. Giữ nguyên những phần không liên quan.
3. Nếu thay đổi lịch trình thì cập nhật schedule.
4. Nếu thay đổi chi phí thì tính lại budget.
5. Không xóa khách sạn nếu người dùng không yêu cầu.
6. Không tự tạo propertyId.
7. Không tự tạo roomId.
8. Trả về TOÀN BỘ kế hoạch.
9. Chỉ trả về JSON.
10. Không dùng Markdown.
11. Không dùng ```json.

CẤU TRÚC:

{
  "destination": "",
  "summary": "",

  "budget": {
    "hotel": 0,
    "food": 0,
    "transport": 0,
    "activities": 0,
    "other": 0,
    "total": 0
  },

  "hotels": [
    {
      "propertyId": "",
      "roomId": "",
      "reason": "",
      "estimatedTotal": 0
    }
  ],

  "itinerary": [
    {
      "day": 1,
      "title": "",
      "activities": [],
      "estimatedCost": 0,
      "schedule": [
        {
          "time": "",
          "activity": "",
          "place": "",
          "transport": "",
          "cost": 0,
          "note": ""
        }
      ]
    }
  ],

  "restaurants": [
    {
      "name": "",
      "description": "",
      "estimatedCost": 0
    }
  ],

  "places": [
    {
      "name": "",
      "description": "",
      "estimatedCost": 0
    }
  ]
}
''';
  }

  // ============================================================
  // CALL GEMINI
  // ============================================================

  Future<AiTravelPlan> _generateFromGemini(
    String prompt,
  ) async {
    final model =
        FirebaseAI.googleAI()
            .generativeModel(
      model: 'gemini-3.8-flash',
    );

    final response =
        await model.generateContent([
      Content.text(prompt),
    ]);

    final responseText =
        response.text?.trim();

    if (responseText == null ||
        responseText.isEmpty) {
      throw Exception(
        'Gemini không trả về dữ liệu.',
      );
    }

    var jsonText = responseText;

    if (jsonText.startsWith('```')) {
      jsonText = jsonText
          .replaceFirst(
            RegExp(r'^```json\s*'),
            '',
          )
          .replaceFirst(
            RegExp(r'^```\s*'),
            '',
          )
          .replaceFirst(
            RegExp(r'\s*```$'),
            '',
          )
          .trim();
    }

    final decoded =
        jsonDecode(jsonText);

    if (decoded is! Map) {
      throw Exception(
        'Dữ liệu AI không đúng định dạng.',
      );
    }

    return AiTravelPlan.fromJson(
      Map<String, dynamic>.from(
        decoded,
      ),
    );
  }

  // ============================================================
  // DETECT QUOTA / API ERROR
  // ============================================================

  bool _isQuotaOrApiError(
    Object error,
  ) {
    final text =
        error.toString().toLowerCase();

    return text.contains(
          'quota',
        ) ||
        text.contains(
          'exceeded',
        ) ||
        text.contains(
          'rate limit',
        ) ||
        text.contains(
          'rate-limit',
        ) ||
        text.contains(
          'resource_exhausted',
        ) ||
        text.contains(
          '429',
        ) ||
        text.contains(
          'genai config',
        ) ||
        text.contains(
          'internal',
        );
  }

  // ============================================================
  // DEMO PLAN
  // ============================================================

  AiTravelPlan _buildDemoPlan({
    required String destination,
    required int days,
    required int guests,
    required int budget,
    required List<Map<String, dynamic>>
        hotelInventory,
  }) {
    final hotel =
        hotelInventory.first;

    final roomPrice =
        (hotel['pricePerNight']
                as num?)
            ?.toInt() ??
        0;

    final hotelTotal =
        roomPrice * days;

    final foodBudget =
        (budget * 0.25).round();

    final transportBudget =
        (budget * 0.10).round();

    final activityBudget =
        (budget * 0.15).round();

    final otherBudget =
        (budget * 0.05).round();

    final calculatedTotal =
        hotelTotal +
            foodBudget +
            transportBudget +
            activityBudget +
            otherBudget;

    final total =
        calculatedTotal > budget
            ? calculatedTotal
            : budget;

    final itinerary =
        List<AiDayPlan>.generate(
      days,
      (index) {
        final day =
            index + 1;

        return AiDayPlan(
          day: day,
          title:
              _demoDayTitle(
            destination,
            day,
          ),
          activities: [
            'Khám phá $destination',
            'Tham quan địa điểm nổi bật',
            'Ăn tối và nghỉ ngơi',
          ],
          estimatedCost:
              (activityBudget / days)
                  .round(),
          schedule:
              _buildDemoSchedule(
            destination: destination,
            day: day,
            guests: guests,
            activityBudget:
                (activityBudget / days)
                    .round(),
          ),
        );
      },
    );

    return AiTravelPlan(
      destination: destination,
      summary:
          'Đây là kế hoạch Demo được LuxeStay tạo '
          'tự động. Kế hoạch bao gồm lịch trình, '
          'địa điểm tham quan, nhà hàng, ngân sách '
          'và phòng khách sạn phù hợp từ dữ liệu LuxeStay.',
      budget: AiBudget(
        hotel: hotelTotal,
        food: foodBudget,
        transport: transportBudget,
        activities:
            activityBudget,
        other: otherBudget,
        total: total,
      ),
      hotels: [
        AiHotelRecommendation(
          propertyId:
              hotel['propertyId']
                  ?.toString() ??
              '',
          roomId:
              hotel['roomId']
                  ?.toString() ??
              '',
          reason:
              'Phòng được lấy trực tiếp từ dữ liệu '
              'LuxeStay và đang còn phòng.',
          estimatedTotal:
              hotelTotal,
        ),
      ],
      itinerary: itinerary,
      restaurants: _buildDemoRestaurants(
        destination,
        guests,
      ),
      places: _buildDemoPlaces(
        destination,
      ),
    );
  }

  // ============================================================
  // DEMO DAY TITLE
  // ============================================================

  String _demoDayTitle(
    String destination,
    int day,
  ) {
    final titles = [
      'Khám phá trung tâm',
      'Tham quan địa điểm nổi bật',
      'Trải nghiệm ẩm thực',
      'Khám phá thiên nhiên',
      'Ngày thư giãn',
    ];

    return titles[
        (day - 1) % titles.length];
  }

  // ============================================================
  // DEMO SCHEDULE
  // ============================================================

  List<AiScheduleItem>
      _buildDemoSchedule({
    required String destination,
    required int day,
    required int guests,
    required int activityBudget,
  }) {
    final destinationLower =
        destination.toLowerCase();

    String place1 =
        'Trung tâm $destination';

    String place2 =
        'Địa điểm nổi bật $destination';

    String place3 =
        'Nhà hàng địa phương';

    if (destinationLower
        .contains('đà nẵng')) {
      if (day == 1) {
        place1 = 'Sân bay Đà Nẵng';
        place2 = 'Bán đảo Sơn Trà';
        place3 = 'Nhà hàng đặc sản Đà Nẵng';
      } else if (day == 2) {
        place1 = 'Ngũ Hành Sơn';
        place2 = 'Bãi biển Mỹ Khê';
        place3 = 'Nhà hàng hải sản';
      } else {
        place1 = 'Cầu Rồng';
        place2 = 'Chợ Hàn';
        place3 = 'Nhà hàng địa phương';
      }
    }

    final transportCost =
        (activityBudget * 0.35)
            .round();

    final visitCost =
        (activityBudget * 0.40)
            .round();

    final foodCost =
        (activityBudget * 0.25)
            .round();

    return [
      AiScheduleItem(
        time: '07:00–09:00',
        activity: 'Ăn sáng & di chuyển',
        place: place1,
        transport: 'Taxi',
        cost: transportCost,
        note:
            'Khởi động ngày mới',
      ),
      AiScheduleItem(
        time: '09:30–11:30',
        activity: 'Tham quan',
        place: place2,
        transport: 'Xe máy',
        cost: visitCost,
        note:
            'Kiểm tra thời gian mở cửa',
      ),
      AiScheduleItem(
        time: '12:00–13:30',
        activity: 'Ăn trưa',
        place: place3,
        transport: 'Đi bộ',
        cost: foodCost,
        note:
            'Ưu tiên món đặc sản địa phương',
      ),
      AiScheduleItem(
        time: '14:00–17:00',
        activity: 'Khám phá',
        place:
            'Điểm tham quan $destination',
        transport: 'Xe máy',
        cost: visitCost,
        note:
            'Có thể điều chỉnh theo thời tiết',
      ),
      AiScheduleItem(
        time: '18:00–20:00',
        activity: 'Ăn tối & nghỉ ngơi',
        place:
            'Nhà hàng $destination',
        transport: 'Đi bộ',
        cost: foodCost,
        note:
            'Kết thúc ngày',
      ),
    ];
  }

  // ============================================================
  // DEMO RESTAURANTS
  // ============================================================

  List<AiRestaurant>
      _buildDemoRestaurants(
    String destination,
    int guests,
  ) {
    final cost =
        250000 * guests;

    return [
      AiRestaurant(
        name:
            'Nhà hàng đặc sản $destination',
        description:
            'Gợi ý trải nghiệm các món đặc sản địa phương.',
        estimatedCost:
            cost,
      ),
      AiRestaurant(
        name:
            'Nhà hàng hải sản địa phương',
        description:
            'Phù hợp cho bữa tối và nhóm khách du lịch.',
        estimatedCost:
            cost + 100000,
      ),
      AiRestaurant(
        name:
            'Quán ăn địa phương nổi tiếng',
        description:
            'Lựa chọn tiết kiệm cho chuyến đi.',
        estimatedCost:
            150000 * guests,
      ),
    ];
  }

  // ============================================================
  // DEMO PLACES
  // ============================================================

  List<AiPlace> _buildDemoPlaces(
    String destination,
  ) {
    final lower =
        destination.toLowerCase();

    if (lower.contains('đà nẵng')) {
      return [
        const AiPlace(
          name: 'Bán đảo Sơn Trà',
          description:
              'Địa điểm nổi bật với cảnh biển và thiên nhiên.',
          estimatedCost: 0,
        ),
        const AiPlace(
          name: 'Ngũ Hành Sơn',
          description:
              'Khu danh thắng nổi tiếng của Đà Nẵng.',
          estimatedCost: 50000,
        ),
        const AiPlace(
          name: 'Bãi biển Mỹ Khê',
          description:
              'Một trong những điểm biển nổi tiếng.',
          estimatedCost: 0,
        ),
        const AiPlace(
          name: 'Cầu Rồng',
          description:
              'Địa điểm phù hợp tham quan vào buổi tối.',
          estimatedCost: 0,
        ),
      ];
    }

    return [
      AiPlace(
        name:
            'Địa điểm nổi bật $destination',
        description:
            'Điểm tham quan được đề xuất trong kế hoạch.',
        estimatedCost: 0,
      ),
      AiPlace(
        name:
            'Trung tâm $destination',
        description:
            'Khám phá khu vực trung tâm và văn hóa địa phương.',
        estimatedCost: 0,
      ),
      AiPlace(
        name:
            'Khu vui chơi $destination',
        description:
            'Địa điểm phù hợp để trải nghiệm và thư giãn.',
        estimatedCost: 100000,
      ),
    ];
  }

  // ============================================================
  // DEMO CHAT REVISION
  // ============================================================

  AiTravelPlan _reviseDemoPlan({
    required AiTravelPlan currentPlan,
    required String userRequest,
  }) {
    final request =
        userRequest.toLowerCase();

    var updatedPlan =
        currentPlan;

    // ----------------------------------------------------------
    // GIẢM CHI PHÍ
    // ----------------------------------------------------------

    if (request.contains('giảm') ||
        request.contains('rẻ') ||
        request.contains('tiết kiệm')) {
      final newBudget =
          AiBudget(
        hotel: currentPlan.budget.hotel,
        food:
            (currentPlan.budget.food *
                    0.85)
                .round(),
        transport:
            (currentPlan.budget.transport *
                    0.85)
                .round(),
        activities:
            (currentPlan.budget.activities *
                    0.80)
                .round(),
        other:
            currentPlan.budget.other,
        total:
            (currentPlan.budget.total *
                    0.88)
                .round(),
      );

      updatedPlan =
          AiTravelPlan(
        destination:
            currentPlan.destination,
        summary:
            '${currentPlan.summary} '
            'Đã điều chỉnh theo yêu cầu tiết kiệm chi phí.',
        budget: newBudget,
        hotels:
            currentPlan.hotels,
        itinerary:
            currentPlan.itinerary,
        restaurants:
            currentPlan.restaurants,
        places:
            currentPlan.places,
      );
    }

    // ----------------------------------------------------------
    // THÊM BÀ NÀ HILLS
    // ----------------------------------------------------------

    if (request.contains(
          'bà nà',
        ) ||
        request.contains(
          'ba na',
        )) {
      final itinerary =
          currentPlan.itinerary
              .map(
        (day) {
          if (request.contains(
            'ngày ${day.day}',
          )) {
            return AiDayPlan(
              day: day.day,
              title:
                  'Khám phá Bà Nà Hills',
              activities: [
                'Đi Bà Nà Hills',
                'Cầu Vàng',
                'French Village',
              ],
              estimatedCost:
                  day.estimatedCost +
                      300000,
              schedule: [
                AiScheduleItem(
                  time:
                      '07:00–08:30',
                  activity:
                      'Di chuyển',
                  place:
                      'Bà Nà Hills',
                  transport:
                      'Taxi/Ô tô',
                  cost: 300000,
                  note:
                      'Nên xuất phát sớm',
                ),
                const AiScheduleItem(
                  time:
                      '09:00–11:30',
                  activity:
                      'Tham quan Cầu Vàng',
                  place:
                      'Cầu Vàng',
                  transport:
                      'Cáp treo',
                  cost: 0,
                  note:
                      'Chụp ảnh và tham quan',
                ),
                const AiScheduleItem(
                  time:
                      '12:00–13:30',
                  activity:
                      'Ăn trưa',
                  place:
                      'Bà Nà Hills',
                  transport:
                      'Đi bộ',
                  cost: 300000,
                  note:
                      'Ăn trưa tại khu du lịch',
                ),
                const AiScheduleItem(
                  time:
                      '14:00–17:00',
                  activity:
                      'Khám phá French Village',
                  place:
                      'French Village',
                  transport:
                      'Đi bộ',
                  cost: 0,
                  note:
                      'Tham quan và vui chơi',
                ),
              ],
            );
          }

          return day;
        },
      ).toList();

      updatedPlan =
          AiTravelPlan(
        destination:
            updatedPlan.destination,
        summary:
            '${updatedPlan.summary} '
            'Đã thêm Bà Nà Hills theo yêu cầu.',
        budget:
            updatedPlan.budget,
        hotels:
            updatedPlan.hotels,
        itinerary:
            itinerary,
        restaurants:
            updatedPlan.restaurants,
        places:
            updatedPlan.places,
      );
    }

    return updatedPlan;
  }
}