import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageStorageService {
  ImageStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  static const int _maxImageBytes = 10 * 1024 * 1024;
  static const Duration _uploadTimeout = Duration(seconds: 90);
  static const Duration _urlTimeout = Duration(seconds: 30);

  static const String _logName = 'ImageStorage';

  /// Upload một ảnh phòng.
  Future<String> uploadRoomImage({
    required String propertyId,
    required String roomId,
    required XFile image,
    Uint8List? imageBytes,
  }) async {
    final bytes = imageBytes ?? await image.readAsBytes();

    _validateImage(
      bytes,
      errorMessage: 'Ảnh được chọn không có dữ liệu.',
      tooLargeMessage: 'Mỗi ảnh phải nhỏ hơn 10 MB.',
    );

    final extension = _safeExtension(image.name);
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    final path =
        'properties/$propertyId/rooms/$roomId/$timestamp.$extension';

    return _uploadAndGetUrl(
      path: path,
      bytes: bytes,
      contentType: _contentType(image, extension),
      customMetadata: {'roomId': roomId},
    );
  }

  /// Upload ảnh khách sạn khi chủ sở hữu đăng ký.
  Future<String> uploadOwnerPropertyImage({
    required String ownerId,
    required XFile image,
  }) async {
    final bytes = await image.readAsBytes();

    _validateImage(
      bytes,
      errorMessage: 'Ảnh khách sạn không có dữ liệu.',
      tooLargeMessage: 'Ảnh khách sạn phải nhỏ hơn 10 MB.',
    );

    final extension = _safeExtension(image.name);
    final timestamp = DateTime.now().microsecondsSinceEpoch;

    final path =
        'users/$ownerId/onboarding/property-$timestamp.$extension';

    return _uploadAndGetUrl(
      path: path,
      bytes: bytes,
      contentType: _contentType(image, extension),
    );
  }

  /// Upload nhiều ảnh phòng lần lượt, tránh tạo nhiều tác vụ đồng thời.
  ///
  /// onProgress trả về số ảnh đã hoàn tất và tổng số ảnh.
  /// URL trả về giữ nguyên thứ tự của danh sách đầu vào.
  Future<List<String>> uploadRoomImages({
    required String propertyId,
    required String roomId,
    required List<XFile> images,
    void Function(int completed, int total)? onProgress,
  }) async {
    final urls = <String>[];

    for (var index = 0; index < images.length; index++) {
      final url = await uploadRoomImage(
        propertyId: propertyId,
        roomId: roomId,
        image: images[index],
      );

      urls.add(url);
      onProgress?.call(index + 1, images.length);
    }

    return urls;
  }

  /// Upload dữ liệu lên Storage và lấy download URL.
  Future<String> _uploadAndGetUrl({
    required String path,
    required Uint8List bytes,
    required String contentType,
    Map<String, String>? customMetadata,
  }) async {
    final reference = _storage.ref().child(path);
    final stopwatch = Stopwatch()..start();

    _log(
      'Bắt đầu upload: $path | '
      'Dung lượng: '
      '${(bytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(2)} MB',
    );

    final task = reference.putData(
      bytes,
      SettableMetadata(
        contentType: contentType,
        customMetadata: customMetadata,
      ),
    );

    final subscription = task.snapshotEvents.listen(
      (snapshot) {
        final total = snapshot.totalBytes;
        final transferred = snapshot.bytesTransferred;
        final percentage =
            total > 0 ? transferred * 100 / total : 0.0;

        _log(
          'Tiến trình: ${percentage.toStringAsFixed(1)}% | '
          'Trạng thái: ${snapshot.state.name} | '
          '$transferred/$total bytes',
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        _log(
          'Lỗi theo dõi tiến trình upload',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );

    try {
      final result = await task.timeout(
        _uploadTimeout,
        onTimeout: () async {
          await task.cancel();

          throw TimeoutException(
            'Tải ảnh lên quá 90 giây. '
            'Vui lòng kiểm tra mạng và thử lại.',
          );
        },
      );

      _log('Upload thành công sau ${stopwatch.elapsed}.');

      final url = await result.ref.getDownloadURL().timeout(
        _urlTimeout,
        onTimeout: () {
          throw TimeoutException(
            'Upload thành công nhưng lấy URL ảnh quá 30 giây.',
          );
        },
      );

      _log('Hoàn tất sau ${stopwatch.elapsed}.');

      return url;
    } on FirebaseException catch (error, stackTrace) {
      _log(
        'Firebase error: ${error.code} | ${error.message} | Path: $path',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } on TimeoutException catch (error, stackTrace) {
      _log(
        'Timeout: $error | Path: $path',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (error, stackTrace) {
      _log(
        'Upload thất bại: $error | Path: $path',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      await subscription.cancel();
    }
  }

  /// Kiểm tra dữ liệu và dung lượng ảnh.
  void _validateImage(
    Uint8List bytes, {
    required String errorMessage,
    required String tooLargeMessage,
  }) {
    if (bytes.isEmpty) {
      throw FormatException(errorMessage);
    }

    if (bytes.lengthInBytes > _maxImageBytes) {
      throw FormatException(tooLargeMessage);
    }
  }

  /// Lấy phần mở rộng an toàn từ tên file.
  String _safeExtension(String filename) {
    final extension = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : 'jpg';

    return RegExp(r'^[a-z0-9]{2,5}$').hasMatch(extension)
        ? extension
        : 'jpg';
  }

  /// Xác định MIME type của ảnh.
  String _contentType(XFile image, String extension) {
    final mimeType = image.mimeType;

    if (mimeType != null &&
        mimeType.startsWith('image/') &&
        mimeType.length > 'image/'.length) {
      return mimeType;
    }

    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'avif':
        return 'image/avif';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'application/octet-stream';
    }
  }

  /// Ghi log bằng dart:developer, không dùng print().
  void _log(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: _logName,
      error: error,
      stackTrace: stackTrace,
    );
  }
}