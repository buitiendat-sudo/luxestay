'use strict';

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');

const geminiApiKey = defineSecret('GEMINI_API_KEY');
const modelName = 'gemini-3.1-flash-lite';

const stringSchema = { type: 'STRING' };
const integerSchema = { type: 'INTEGER' };

function objectSchema(properties) {
  return {
    type: 'OBJECT',
    properties,
    required: Object.keys(properties),
  };
}

function arraySchema(items) {
  return { type: 'ARRAY', items };
}

const responseSchema = objectSchema({
  destination: stringSchema,
  summary: stringSchema,
  budget: objectSchema({
    hotel: integerSchema,
    food: integerSchema,
    transport: integerSchema,
    activities: integerSchema,
    other: integerSchema,
    total: integerSchema,
  }),
  hotels: arraySchema(objectSchema({
    propertyId: stringSchema,
    roomId: stringSchema,
    reason: stringSchema,
    estimatedTotal: integerSchema,
  })),
  itinerary: arraySchema(objectSchema({
    day: integerSchema,
    title: stringSchema,
    activities: arraySchema(stringSchema),
    estimatedCost: integerSchema,
  })),
  restaurants: arraySchema(objectSchema({
    name: stringSchema,
    description: stringSchema,
    estimatedCost: integerSchema,
  })),
  places: arraySchema(objectSchema({
    name: stringSchema,
    description: stringSchema,
    estimatedCost: integerSchema,
  })),
});

exports.generateTravelPlan = onCall(
  {
    region: 'asia-southeast1',
    enforceAppCheck: process.env.FUNCTIONS_EMULATOR !== 'true',
    secrets: [geminiApiKey],
    timeoutSeconds: 60,
    maxInstances: 10,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        'unauthenticated',
        'Bạn cần đăng nhập để tạo kế hoạch du lịch.',
      );
    }

    const {
      destination,
      days,
      guests,
      budget,
      hotelInventory,
    } = request.data ?? {};

    if (
      typeof destination !== 'string' ||
      destination.trim().length === 0 ||
      !Number.isInteger(days) || days < 1 || days > 30 ||
      !Number.isInteger(guests) || guests < 1 || guests > 20 ||
      !Number.isInteger(budget) || budget < 100000 ||
      !Array.isArray(hotelInventory) ||
      hotelInventory.length === 0 || hotelInventory.length > 300
    ) {
      throw new HttpsError('invalid-argument', 'Thông tin chuyến đi không hợp lệ.');
    }

    const prompt = `
Bạn là AI Travel Planner của ứng dụng đặt phòng LuxeStay.

Thông tin chuyến đi:
- Điểm đến: ${destination.trim()}
- Số ngày: ${days}
- Số người: ${guests}
- Ngân sách: ${budget} VND

Lập lịch trình theo từng ngày, gợi ý địa điểm tham quan và nhà hàng, đồng thời
ước tính chi phí. Bắt buộc chọn khách sạn/phòng từ danh sách LuxeStay dưới đây.

Quy tắc:
- Chỉ dùng propertyId và roomId có trong danh sách; không tự tạo ID hay tên khách sạn.
- Ưu tiên phòng còn trống, đúng điểm đến và phù hợp ngân sách.
- estimatedTotal là giá phòng mỗi đêm nhân với số đêm.
- Chọn tối đa 3 phòng; phân bổ ngân sách vào hotel, food, transport, activities,
  other và total; không cố tình vượt ngân sách.
- Chỉ trả về JSON đúng schema, không markdown hoặc giải thích bên ngoài JSON.

Danh sách khách sạn và phòng LuxeStay:
${JSON.stringify(hotelInventory)}
`;

    try {
      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': geminiApiKey.value(),
          },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: {
              responseMimeType: 'application/json',
              responseSchema,
            },
          }),
          signal: AbortSignal.timeout(55000),
        },
      );

      if (!response.ok) {
        logger.error('Gemini request failed', { status: response.status });
        throw new HttpsError(
          response.status === 429 ? 'resource-exhausted' : 'unavailable',
          'Gemini hiện không thể tạo kế hoạch. Vui lòng thử lại sau.',
        );
      }

      const result = await response.json();
      const text = result.candidates?.[0]?.content?.parts
        ?.map((part) => part.text ?? '')
        .join('');
      if (typeof text !== 'string' || text.trim().length === 0) {
        throw new HttpsError('internal', 'Gemini không trả về dữ liệu.');
      }

      return JSON.parse(text);
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error('Travel plan generation failed', error);
      throw new HttpsError(
        'internal',
        'Không thể tạo kế hoạch lúc này. Vui lòng thử lại.',
      );
    }
  },
);