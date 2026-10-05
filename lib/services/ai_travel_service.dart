import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../models/ai_travel_plan.dart';
import 'firestore_service.dart';

class AiTravelService {
  AiTravelService(this.firestoreService);

  final FirestoreService firestoreService;

  static const int _maxGenerationAttempts = 3;

  // ============================================================
  // TẠO KẾ HOẠCH BAN ĐẦU
  // ============================================================

  Future<AiTravelPlan> generateTravelPlan({
    required String destination,
    required int days,
    required int guests,
    required int budget,
  }) async {
    final properties = await firestoreService.getProperties().first;

    final destinationText = destination.trim().toLowerCase();

    final matchingProperties = properties.where((property) {
      if (destinationText.isEmpty) {
        return true;
      }

      return property.location.toLowerCase().contains(destinationText) ||
          property.name.toLowerCase().contains(destinationText);
    }).toList();

    final sourceProperties = matchingProperties.isEmpty
        ? properties
        : matchingProperties;

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
          if (room.availableCount <= 0) {
            continue;
          }

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
      throw Exception('Không tìm thấy phòng khách sạn phù hợp trong LuxeStay.');
    }

    final inventoryForAi = hotelInventory.take(20).toList();

    final prompt =
        '''
Bạn là AI Travel Planner của ứng dụng LuxeStay.

Điểm đến: $destination
Số ngày: $days
Số khách: $guests
Ngân sách: $budget VND

Hãy tạo kế hoạch du lịch hoàn chỉnh.

Mỗi ngày phải có bảng lịch trình chi tiết.

Mỗi dòng lịch trình gồm:

- time: thời gian
- activity: hoạt động
- place: địa điểm
- transport: phương tiện
- cost: chi phí bằng VND
- note: ghi chú

BẮT BUỘC:
- Có lịch trình cho đủ $days ngày.
- Có khách sạn/phòng LuxeStay.
- Chỉ dùng propertyId và roomId có trong dữ liệu.
- Không tự tạo ID khách sạn/phòng.
- Chỉ chọn phòng availableCount > 0.
- Ưu tiên phòng phù hợp ngân sách.
- Có địa điểm tham quan.
- Có nhà hàng.
- Có tổng ngân sách.

DỮ LIỆU KHÁCH SẠN LUXESTAY:

${jsonEncode(inventoryForAi)}

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
          "time": "07:00-09:00",
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

    return _generateFromPrompt(prompt);
  }

  // ============================================================
  // CHATBOT - SỬA KẾ HOẠCH
  // ============================================================

  Future<AiTravelPlan> reviseTravelPlan({
    required AiTravelPlan currentPlan,
    required String userRequest,
  }) async {
    final prompt =
        '''
Bạn là trợ lý AI của LuxeStay.

Đây là kế hoạch du lịch hiện tại:

${jsonEncode(currentPlan.toJson())}

Yêu cầu chỉnh sửa của người dùng:

$userRequest

Hãy chỉnh sửa kế hoạch theo đúng yêu cầu.

QUY TẮC:

1. Chỉ thay đổi những phần người dùng yêu cầu.
2. Giữ nguyên những phần không liên quan.
3. Nếu người dùng yêu cầu đổi lịch trình, hãy cập nhật schedule.
4. Nếu người dùng yêu cầu đổi ngân sách, hãy tính lại budget.
5. Nếu người dùng yêu cầu đổi ngày, hãy cập nhật đúng ngày.
6. Vẫn phải có khách sạn LuxeStay.
7. Không được xóa toàn bộ khách sạn nếu người dùng không yêu cầu.
8. Không được tự tạo propertyId hoặc roomId.
9. Giữ nguyên propertyId và roomId hiện tại nếu không cần đổi khách sạn.
10. Trả về TOÀN BỘ kế hoạch sau khi chỉnh sửa.
11. Trả về JSON thuần túy.
12. Không dùng Markdown.
13. Không dùng ```json.

CẤU TRÚC JSON:

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

    return _generateFromPrompt(prompt);
  }

  // ============================================================
  // GEMINI
  // ============================================================

  Future<AiTravelPlan> _generateFromPrompt(
    String prompt, {
    int attempt = 1,
  }) async {
    try {
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-3.8-flash',
      );

      final response = await model.generateContent([Content.text(prompt)]);

      final responseText = response.text?.trim();

      if (responseText == null || responseText.isEmpty) {
        throw Exception('Gemini không trả về dữ liệu.');
      }

      var jsonText = responseText;

      if (jsonText.startsWith('```')) {
        jsonText = jsonText
            .replaceFirst(RegExp(r'^```json\s*'), '')
            .replaceFirst(RegExp(r'^```\s*'), '')
            .replaceFirst(RegExp(r'\s*```$'), '')
            .trim();
      }

      final decoded = jsonDecode(jsonText);

      if (decoded is! Map) {
        throw Exception('Dữ liệu AI không đúng định dạng.');
      }

      return AiTravelPlan.fromJson(Map<String, dynamic>.from(decoded));
    } catch (error) {
      if (_isTemporaryAiError(error)) {
        if (attempt == _maxGenerationAttempts) {
          throw Exception(
            'Dịch vụ AI đang bận. Vui lòng thử lại sau ít phút.',
          );
        }

        await Future<void>.delayed(Duration(seconds: attempt));
        return _generateFromPrompt(prompt, attempt: attempt + 1);
      }

      throw Exception('Không thể xử lý kế hoạch: $error');
    }
  }

  bool _isTemporaryAiError(Object error) {
    final errorText = error.toString().toLowerCase();

    return errorText.contains('server error [500]') ||
        errorText.contains('server error [503]') ||
        errorText.contains('server error [429]') ||
        errorText.contains('high demand') ||
        errorText.contains('service unavailable') ||
        errorText.contains('resource exhausted') ||
        errorText.contains('rate limit');
  }
}
