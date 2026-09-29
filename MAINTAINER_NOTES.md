# LuxeStay Maintainer Notes

Tài liệu này dành cho người tiếp nhận project, debug lỗi và phát triển tiếp. Nội dung phản ánh trạng thái đã kiểm tra ngày 2026-09-30.

## 1. Kiểm tra nhanh

Chạy từ thư mục gốc project:

```powershell
flutter pub get
flutter analyze
flutter test
```

Kết quả lần review gần nhất:

- `flutter analyze`: không có lỗi.
- `flutter test`: tất cả test hiện tại pass.
- Test hiện tại còn rất mỏng; test smoke chỉ kiểm tra test runner, chưa kiểm tra Firebase, auth, Firestore hay UI admin.

Không chạy `futter analyze`; lệnh đúng là `flutter analyze`.

## 2. Chạy ứng dụng

```powershell
flutter run -d chrome
# hoặc
flutter run -d android
```

Firebase được khởi tạo trong `lib/main.dart` trước khi `runApp`.

Project Firebase hiện tại:

- Project ID: `luxestay-1309f`
- Auth đang dùng: Firebase Email/Password
- Firebase options hiện chỉ có Android và Web.

`lib/firebase_options.dart` sẽ ném `UnsupportedError` trên iOS, macOS, Windows và Linux. Nếu cần chạy các nền tảng này, chạy lại FlutterFire CLI từ project Firebase đúng:

```powershell
flutterfire configure
```

Sau đó kiểm tra lại `lib/firebase_options.dart`, `firebase.json` và file native tương ứng.

## 3. Luồng ứng dụng

- `lib/main.dart`: khởi tạo Firebase, đăng ký Provider, app theme và admin dashboard.
- `lib/providers/auth_provider.dart`: đăng nhập, đăng ký, logout và đọc role từ `users/{uid}`.
- `lib/screens/auth/auth_gate.dart`: route người dùng sang customer hoặc admin.
- `lib/services/auth_service.dart`: gọi Firebase Auth và hiện đang ghi user Firestore trong lúc register.
- `lib/services/firestore_service.dart`: gateway chính cho các collection.
- `lib/seed_data.dart`: dữ liệu phát triển, không tự chạy khi mở app.

Role admin hiện được xác định bởi chuỗi `ADMIN` trong document Firestore. Đây chỉ là điều hướng UI, không phải lớp bảo mật. Firestore Rules phải kiểm tra role ở phía server.

## 4. Schema Firestore hiện tại

Các collection đang được sử dụng:

- `properties`: resort; các field chính gồm `name`, `location`, `category`, `image`, `pricePerNight`, `rating`, `reviewCount`, `amenities`.
- `rooms`: được admin service sử dụng cho danh sách phòng và trạng thái `isOnSale`.
- `properties/{propertyId}/rooms`: được customer flow và seed data sử dụng cho phòng thuộc resort.
- `bookings`: booking với `userId`, `propertyId`, `roomId`, `checkIn`, `checkOut`, `rooms`, `pricePerNight`, `totalNights`, `totalPrice`, `status`.
- `users`: hồ sơ người dùng, gồm `email`, `displayName` hoặc `name`, `role`.
- `users/{userId}/favorites`: resort yêu thích.
- `reviews`: seed data có ghi, nhưng model/service/UI review chưa hoàn thiện.

### Việc cần xử lý trước khi mở rộng phòng

Schema phòng đang bị tách làm hai nơi:

- Customer đọc `properties/{propertyId}/rooms`.
- Admin dashboard và `watchRooms()` đọc top-level `rooms`.

Vì vậy seed room có thể hiện ở customer nhưng admin đếm bằng 0. Không sửa riêng một màn hình để che triệu chứng. Cần chọn một schema chuẩn, migrate dữ liệu, rồi cập nhật cả seed, customer, admin và booking.

## 5. Cảnh báo quan trọng

### P0: Firestore Rules chưa có trong repository

Không thấy `firestore.rules` và `firebase.json` chưa cấu hình rules. Các method CRUD client có thể đọc/ghi properties, rooms, bookings, users và favorites. Cần kiểm tra rules đang deploy trên Firebase Console ngay.

Rules tối thiểu phải bảo đảm:

- Chỉ user đăng nhập mới đọc dữ liệu cần thiết.
- User chỉ sửa profile và booking của chính mình.
- User không thể tự đổi `role`, giá, tổng tiền hoặc trạng thái booking tùy ý.
- Chỉ admin được CRUD resort/phòng/user và chuyển trạng thái booking.
- Booking phải kiểm tra ownership, status transition và dữ liệu bắt buộc.

Không dùng việc ẩn nút trên UI làm cơ chế phân quyền.

### P1: Booking chưa chống overbooking và giả giá

Booking đang được tạo từ client dựa trên giá hiển thị. Chưa có transaction, kiểm tra giao ngày, khóa inventory hoặc server-side price validation. Khi nhiều người đặt cùng lúc, số phòng có thể âm hoặc bị đặt trùng.

Hướng sửa: dùng Cloud Function/transaction, đọc lại giá từ Firestore, kiểm tra overlap theo `roomId` và ngày, sau đó ghi booking cùng cập nhật inventory.

### P1: Seed user không phải Firebase Auth user

`lib/seed_data.dart` chỉ tạo document trong `users`; nó không tạo tài khoản Firebase Authentication. Email trong seed không tự đăng nhập được. Nếu cần tài khoản demo, phải tạo Auth users riêng bằng Firebase Console/Admin SDK và ghi đúng UID vào Firestore.

### P1: Register có thể tạo Auth user mồ côi

`AuthService.register()` tạo Auth user rồi ghi Firestore; `AuthProvider.register()` lại ghi user lần nữa với field/role khác (`name`/`customer` so với `displayName`/`CUSTOMER`). Nếu Firestore lỗi, Auth user vẫn tồn tại và lần đăng ký lại báo email đã dùng.

Nên chọn một nơi chịu trách nhiệm tạo user document, thống nhất field/role, và có quy trình rollback hoặc retry rõ ràng.

### P1: AuthGate chưa chờ role

Khi app restore session, `_user` có thể có trước khi `_loadUserRole()` hoàn tất. AuthGate có thể hiển thị customer navigation trong chốc lát cho admin. Thêm trạng thái loading role vào AuthGate; đồng thời vẫn phải bảo vệ bằng Firestore Rules.

### P2: Dữ liệu xấu bị che giấu

`Booking.fromFirestore()` biến ngày thiếu/sai thành `DateTime.now()`. Booking hỏng sẽ trông như booking hôm nay. `FirestoreService` cũng bỏ qua booking parse lỗi mà không báo ra UI. Nên validate và log/hiển thị record lỗi thay vì thay bằng giá trị hiện tại.

## 6. Các tính năng còn dang dở

- Quên mật khẩu chưa gọi `sendPasswordResetEmail`.
- Nút gọi khách và xem chi tiết booking hiện chưa có hành động.
- Lọc phòng, chỉnh giá và quản lý kho phòng còn placeholder.
- Thêm tài khoản admin/user chưa hoàn thiện.
- Reviews và notification service chưa có luồng hoàn chỉnh.
- Một số action favorite/share ở customer chưa hoàn thiện.
- Dashboard booking hiện đếm tổng booking, chưa lọc theo ngày và chưa tính doanh thu thật.

Khi hoàn thiện một action, thêm test cho cả trạng thái thành công, lỗi mạng/quyền và dữ liệu rỗng.

## 7. Quy trình debug đề xuất

1. Chạy `flutter analyze` và `flutter test` trước khi đọc sâu.
2. Xác nhận Firebase project và platform trong `lib/firebase_options.dart`.
3. Kiểm tra user hiện tại trong Firebase Auth; không suy ra Auth account chỉ từ document `users`.
4. Kiểm tra đúng collection/path trong Firestore, đặc biệt với rooms.
5. Kiểm tra Firestore Rules và Firebase Console logs trước khi sửa UI.
6. Với booking, kiểm tra `userId`, `propertyId`, `roomId`, `checkIn`, `checkOut`, `status` và giá server.
7. Khi sửa schema, cập nhật đồng thời model, seed data, service và mọi màn hình đọc collection đó.

## 8. Checklist trước khi merge

- [ ] `flutter analyze` sạch.
- [ ] `flutter test` pass.
- [ ] Có test cho phần logic mới, không chỉ smoke test.
- [ ] Firestore Rules đã review và deploy đúng project.
- [ ] Không dùng dữ liệu giá/tồn kho từ client làm nguồn sự thật.
- [ ] Không thêm field/collection mới mà chưa cập nhật schema note.
- [ ] Kiểm tra loading, empty, error và permission-denied state.
- [ ] Kiểm tra Android/Web; chỉ ghi hỗ trợ nền tảng nào đã có Firebase config.
