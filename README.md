# LuxeStay - Ghi chú bàn giao

## Tổng quan

LuxeStay là ứng dụng đặt phòng viết bằng Flutter/Dart, dùng Firebase Authentication, Cloud Firestore, Firebase Storage và Cloud Functions. Giao diện và nội dung hiện chủ yếu bằng tiếng Việt.

## Khởi chạy và điều hướng

- Entrypoint: `lib/main.dart`. Khởi tạo locale `vi_VN`, Firebase, App Check và các Provider dùng toàn app.
- Chạy web local: `flutter pub get`, sau đó `flutter run -d chrome`.
- `AuthGate` (`lib/screens/auth/auth_gate.dart`) chuyển người dùng theo role: CUSTOMER vào điều hướng khách, OWNER vào onboarding hoặc dashboard, ADMIN vào dashboard quản trị.
- Các màn customer chính: khám phá, yêu thích, chuyến đi, tài khoản.
- Owner có dashboard, quản lý phòng và quản lý booking. Admin có dashboard operations, khách sạn và người dùng.

## Ranh giới dữ liệu

- `lib/providers/auth_provider.dart`: trạng thái đăng nhập, role và onboarding chủ khách sạn.
- `lib/services/firestore_service.dart`: thao tác Firestore; dùng các model trong `lib/models/` để parse dữ liệu.
- Các collection chính: `users`, `properties`, `bookings`, `reviews`; phòng nằm trong subcollection `properties/{propertyId}/rooms`, yêu thích nằm trong `users/{userId}/favorites`.
- `firestore.rules` là nơi quyết định quyền đọc/ghi thực tế. Không nới quyền client để sửa dữ liệu tổng hợp rating; nếu cần đồng bộ server, dùng Admin SDK trong Cloud Functions.
- `lib/firebase_options.dart`, `firebase.json`, rules và cấu hình nền tảng gắn với Firebase project `luxestay-1309f`.

## Cloud Functions và rating

`functions/index.js` hiện export:

- `getRevenueReport` (callable)
- `generateTravelPlan` (callable, dùng secret `GEMINI_API_KEY`)
- `aggregatePropertyReviewStats` (Firestore trigger trên `reviews/{reviewId}`)

`aggregatePropertyReviewStats` tính lại `properties.rating` và `properties.reviewCount` từ các review. Trigger này **chưa deploy thành công**: Firebase project đang ở gói Spark; triển khai Cloud Functions yêu cầu gói Blaze. Trước khi deploy production cần chủ project quyết định nâng gói. Lệnh triển khai riêng trigger sau khi đủ điều kiện: `firebase deploy --only functions:aggregatePropertyReviewStats --project luxestay-1309f`.

Trong lúc chưa có trigger, Explore và admin có thể tính rating trực tiếp từ stream reviews qua `FirestoreService.watchReviewSummaries()`. Vì vậy field `rating`/`reviewCount` lưu trên property vẫn có thể cũ, và những màn khác đọc trực tiếp property cần được kiểm tra nếu cần rating realtime.

## Kiểm tra và tình trạng test

- Chạy analyzer: `flutter analyze`.
- Test files trong `test/` đã được xóa theo yêu cầu; hiện không có test suite để chạy. Khôi phục test trước khi dựa vào kiểm thử tự động trong CI.
- Kiểm tra cú pháp Functions: `node --check functions/index.js`.
- Script `npm --prefix functions run lint` hiện tham chiếu `functions/seed-owner-demo-data.js`, nhưng file đó không có trong workspace; lệnh sẽ lỗi sau khi kiểm tra `index.js`.

## Lưu ý tiếp quản

- `firebase.json` trỏ rules Firestore và Storage tới `firestore.rules` và `storage.rules`; thay đổi local chưa có hiệu lực trên project cho tới khi được deploy.
- Web bật Firebase App Check trong `lib/main.dart`; nếu request bị từ chối, kiểm tra cấu hình App Check của Firebase và môi trường web.
- Khi làm việc với rating, xác định màn đang dùng review stream hay field tổng hợp của property. Khi làm việc với owner booking, query phải giới hạn theo `propertyId` để khớp quyền trong Firestore rules.
