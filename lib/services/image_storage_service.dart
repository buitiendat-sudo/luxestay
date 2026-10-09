import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageStorageService {
  ImageStorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadRoomImage({
    required String propertyId,
    required String roomId,
    required XFile image,
    Uint8List? imageBytes,
  }) async {
    final bytes = imageBytes ?? await image.readAsBytes();
    if (bytes.isEmpty) {
      throw const FormatException('Ảnh được chọn không có dữ liệu.');
    }
    if (bytes.length > 10 * 1024 * 1024) {
      throw const FormatException('Mỗi ảnh phải nhỏ hơn 10 MB.');
    }

    final extension = image.name.contains('.')
        ? image.name.split('.').last.toLowerCase()
        : 'jpg';
    final safeExtension = RegExp(r'^[a-z0-9]{2,5}$').hasMatch(extension)
        ? extension
        : 'jpg';
    final reference = _storage.ref().child(
      'properties/$propertyId/rooms/$roomId/${DateTime.now().microsecondsSinceEpoch}.$safeExtension',
    );
    final result = await reference.putData(
      bytes,
      SettableMetadata(
        contentType: image.mimeType ?? 'image/jpeg',
        customMetadata: {'roomId': roomId},
      ),
    );
    return result.ref.getDownloadURL();
  }

  Future<String> uploadOwnerPropertyImage({
    required String ownerId,
    required XFile image,
  }) async {
    final bytes = await image.readAsBytes();
    if (bytes.isEmpty) {
      throw const FormatException('Ảnh được chọn không có dữ liệu.');
    }
    if (bytes.length > 10 * 1024 * 1024) {
      throw const FormatException('Ảnh khách sạn phải nhỏ hơn 10 MB.');
    }

    final extension = image.name.contains('.')
        ? image.name.split('.').last.toLowerCase()
        : 'jpg';
    final safeExtension = RegExp(r'^[a-z0-9]{2,5}$').hasMatch(extension)
        ? extension
        : 'jpg';
    final reference = _storage.ref().child(
      'users/$ownerId/onboarding/property-${DateTime.now().microsecondsSinceEpoch}.$safeExtension',
    );
    final result = await reference.putData(
      bytes,
      SettableMetadata(contentType: image.mimeType ?? 'image/jpeg'),
    );
    return result.ref.getDownloadURL();
  }
}
