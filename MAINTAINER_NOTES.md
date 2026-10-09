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
- `lib/screens/auth/auth_gate.dart`: route người dùng theo role CUSTOMER, OWNER hoặc ADMIN.
- `lib/services/auth_service.dart`: gọi Firebase Auth; `AuthProvider` ghi hồ sơ Firestore.
- `lib/services/firestore_service.dart`: gateway chính cho các collection.
- `lib/seed_data.dart`: dữ liệu phát triển, không tự chạy khi mở app.

Đăng ký công khai chỉ nhận role `CUSTOMER` và `OWNER`. OWNER tạo tài khoản trước, sau đó hoàn tất thông tin khách sạn và chấp thuận điều khoản mẫu trong `lib/screens/auth/owner_onboarding_screen.dart`. Bước này ghi property và bản ghi chấp thuận cùng batch, liên kết qua `users/{uid}.propertyId` và `properties/{propertyId}.ownerId`. Role `ADMIN` phải được cấp nội bộ, không qua form đăng ký. Firestore Rules và callable báo cáo doanh thu enforce quyền ở backend. Điều khoản hiện là nội dung mẫu, không phải hợp đồng pháp lý đã được phê duyệt.

## 4. Schema Firestore hiện tại

Các collection đang được sử dụng:

- `properties`: resort; các field chính gồm `name`, `location`, `category`, `image`, `pricePerNight`, `rating`, `reviewCount`, `amenities`.
- `properties/{propertyId}`: thêm `ownerId` cho khách sạn do owner tạo.
- `properties/{propertyId}/rooms`: được customer flow và seed data sử dụng cho phòng thuộc resort.
- `bookings`: booking với `userId`, `propertyId`, `roomId`, `checkIn`, `checkOut`, `rooms`, `pricePerNight`, `totalNights`, `totalPrice`, `status`.
- `users`: hồ sơ người dùng, gồm `email`, `displayName` hoặc `name`, `role`, `propertyId` (owner), `isStaff` (nhân sự được admin gán).
- `users/{userId}/favorites`: resort yêu thích.
- `reviews`: seed data có ghi, nhưng model/service/UI review chưa hoàn thiện.

### Schema phòng còn collection legacy

Phòng đang được dùng tại:

- Customer đọc `properties/{propertyId}/rooms`.
- Owner quản lý `properties/{propertyId}/rooms`.
- `FirestoreService.watchRooms()` và các method top-level `rooms` vẫn còn để tương thích dữ liệu cũ; không dùng cho quyền owner/admin mới.

Seed data hiện chủ yếu ghi hạng phòng nested dưới property. Tránh thêm luồng ghi mới vào collection top-level `rooms`.

## 5. Cảnh báo quan trọng

### P0: Firestore Rules phải được deploy sau thay đổi quyền

`firestore.rules` đã có trong repository và được khai báo trong `firebase.json`. Phải deploy rules cùng callable function `getRevenueReport` trước khi dùng các luồng mới.

Rules giới hạn:

- Chỉ user đăng nhập mới đọc dữ liệu cần thiết.
- CUSTOMER không thể tự cấp role OWNER/ADMIN hoặc gán mình làm nhân sự.
- OWNER chỉ sửa phòng và booking có `propertyId` trùng khách sạn được liên kết.
- ADMIN quản lý property và nhân sự; không đọc booking chi tiết hoặc ghi phòng.
- Báo cáo doanh thu chỉ trả số liệu tổng hợp qua callable function.

Không dùng việc ẩn nút trên UI làm cơ chế phân quyền.

### P1: Booking chưa chống overbooking và giả giá

Booking đang được tạo từ client dựa trên giá hiển thị. Chưa có transaction, kiểm tra giao ngày, khóa inventory hoặc server-side price validation. Khi nhiều người đặt cùng lúc, số phòng có thể âm hoặc bị đặt trùng.

Hướng sửa: dùng Cloud Function/transaction, đọc lại giá từ Firestore, kiểm tra overlap theo `roomId` và ngày, sau đó ghi booking cùng cập nhật inventory.

### P1: Seed user không phải Firebase Auth user

`lib/seed_data.dart` chỉ tạo document trong `users`; nó không tạo tài khoản Firebase Authentication. Email trong seed không tự đăng nhập được. Property, hồ sơ, đánh giá và booking trong file đều là dữ liệu tổng hợp để demo, có `isDemo: true`, không phải hoạt động khách hàng thật hay số liệu khách sạn đã kiểm chứng. Nếu cần tài khoản demo, phải tạo Auth users riêng bằng Firebase Console/Admin SDK và ghi đúng UID vào Firestore.

Để nạp dữ liệu nghiệp vụ cho OWNER đã đăng ký thật, dùng `functions/seed-owner-demo-data.js` với UID của owner. Script kiểm tra liên kết `users/{uid}.propertyId` và `properties/{propertyId}.ownerId`, sau đó tạo phòng, booking và hồ sơ nhân viên demo với ID ổn định. Chỉ chạy trên Firebase Emulator hoặc project test vì Admin SDK bỏ qua Firestore Rules.

### P1: Thanh toán hiện vẫn là mô phỏng phía client

Màn thanh toán hiện tự ghi `paymentStatus: paid` và hiển thị rõ đây là mô phỏng, chưa thu tiền thật. Doanh thu hiện tổng hợp theo trạng thái này; trước khi dùng thật, cần xác thực webhook thanh toán ở backend và cấm client tự đánh dấu đã trả.

### P2: Dữ liệu xấu bị che giấu

`Booking.fromFirestore()` biến ngày thiếu/sai thành `DateTime.now()`. Booking hỏng sẽ trông như booking hôm nay. `FirestoreService` cũng bỏ qua booking parse lỗi mà không báo ra UI. Nên validate và log/hiển thị record lỗi thay vì thay bằng giá trị hiện tại.

## 6. Các tính năng còn dang dở

- Quên mật khẩu chưa gọi `sendPasswordResetEmail`.
- Nút gọi khách và xem chi tiết booking hiện chưa có hành động.
- Gán nhân sự chỉ liên kết hồ sơ Firebase Auth đã tồn tại; tạo Auth user mới cần Admin SDK/backend.
- Reviews và notification service chưa có luồng hoàn chỉnh.
- Một số action favorite/share ở customer chưa hoàn thiện.
- Doanh thu hiện dựa trên trạng thái thanh toán mô phỏng, chưa phải số tiền đối soát từ cổng thanh toán.

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
- [ ] Firestore Rules và callable functions đã review và deploy đúng project.
- [ ] Không dùng dữ liệu giá/tồn kho từ client làm nguồn sự thật.
- [ ] Không thêm field/collection mới mà chưa cập nhật schema note.
- [ ] Kiểm tra loading, empty, error và permission-denied state.
- [ ] Kiểm tra Android/Web; chỉ ghi hỗ trợ nền tảng nào đã có Firebase config.
