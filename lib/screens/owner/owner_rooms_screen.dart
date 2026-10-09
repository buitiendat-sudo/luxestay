import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../services/image_storage_service.dart';
import '../../widgets/admin_chrome.dart';

class OwnerRoomsScreen extends StatefulWidget {
  const OwnerRoomsScreen({super.key});

  @override
  State<OwnerRoomsScreen> createState() => _OwnerRoomsScreenState();
}

String _optimizedRoomImageUrl(String source, {required int width}) {
  final uri = Uri.tryParse(source);
  if (uri == null || uri.host != 'images.unsplash.com') return source;
  return uri
      .replace(
        queryParameters: {
          ...uri.queryParameters,
          'auto': 'format',
          'fit': 'crop',
          'w': '$width',
          'q': '65',
        },
      )
      .toString();
}

class _OwnerRoomsScreenState extends State<OwnerRoomsScreen> {
  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final auth = context.watch<AuthProvider>();
    final isOwner = auth.isOwner;
    final ownerPropertyId = auth.propertyId;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: const AdminHeader(title: 'Quản lý phòng'),
      bottomNavigationBar: AdminBottomNavigation(
        selectedIndex: isOwner ? 1 : 2,
        popToParentOnReselect: true,
      ),
      body: isOwner
          ? ownerPropertyId == null || ownerPropertyId.isEmpty
                ? const Center(child: Text('Chưa có khách sạn được liên kết.'))
                : _roomsForProperty(firestore, ownerPropertyId)
          : const Center(
              child: Text('Chỉ chủ khách sạn mới được quản lý phòng.'),
            ),
    );
  }

  Widget _roomsForProperty(FirestoreService firestore, String propertyId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firestore.watchRoomsByProperty(propertyId),
      builder: (context, roomSnapshot) {
        if (roomSnapshot.hasError) {
          return Center(
            child: Text('Không thể tải phòng: ${roomSnapshot.error}'),
          );
        }
        if (!roomSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rooms = roomSnapshot.data!;
        return ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _RoomOverview(rooms: rooms),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Hạng phòng (${rooms.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _editRoom(context, propertyId),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm phòng'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (rooms.isEmpty)
              const AdminEmptyState(
                icon: Icons.bed_outlined,
                title: 'Chưa có hạng phòng',
                description: 'Thêm loại phòng đầu tiên cho khách sạn.',
              )
            else
              ...rooms.map(
                (room) => _RoomCard(
                  room: room,
                  onEdit: () => _editRoom(context, propertyId, room),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _editRoom(
    BuildContext context,
    String propertyId, [
    Map<String, dynamic>? room,
  ]) async {
    final messenger = ScaffoldMessenger.of(context);
    final name = TextEditingController(text: room?['name']?.toString() ?? '');
    final price = TextEditingController(
      text: room?['pricePerNight']?.toString() ?? '',
    );
    final count = TextEditingController(
      text: room?['availableCount']?.toString() ?? '1',
    );
    final area = TextEditingController(text: room?['area']?.toString() ?? '0');
    final bed = TextEditingController(text: room?['bedType']?.toString() ?? '');
    final view = TextEditingController(text: room?['view']?.toString() ?? '');
    final bedCount = TextEditingController(
      text: room?['bedCount']?.toString() ?? '1',
    );
    final maxGuests = TextEditingController(
      text: room?['maxGuests']?.toString() ?? '2',
    );
    final featuredAmenities = TextEditingController(
      text: (room?['featuredAmenities'] as List? ?? const []).join(', '),
    );
    final amenities = TextEditingController(
      text: (room?['amenities'] as List? ?? const []).join(', '),
    );
    final imageUrls = <String>{
      if (room?['image']?.toString().trim().isNotEmpty == true)
        room!['image'].toString().trim(),
      ...((room?['images'] as List? ?? const []).map(
        (image) => image.toString(),
      )).where((image) => image.trim().isNotEmpty),
    }.toList();
    final pickedImages = <XFile>[];
    final pickedImageBytes = <XFile, Future<Uint8List>>{};
    final imagePicker = ImagePicker();
    var uploadingImages = false;
    var uploadedImageCount = 0;
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(room == null ? 'Thêm hạng phòng' : 'Sửa hạng phòng'),
          content: Form(
            key: formKey,
            child: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogField(name, 'Tên hạng phòng'),
                    _dialogField(
                      price,
                      'Giá mỗi đêm',
                      numeric: true,
                      minimum: 1,
                    ),
                    _dialogField(
                      count,
                      'Số phòng khả dụng',
                      numeric: true,
                      minimum: 0,
                    ),
                    _dialogField(
                      area,
                      'Diện tích (m²)',
                      numeric: true,
                      minimum: 0,
                    ),
                    _dialogField(bed, 'Loại giường'),
                    _dialogField(
                      bedCount,
                      'Số giường',
                      numeric: true,
                      minimum: 1,
                    ),
                    _dialogField(
                      maxGuests,
                      'Số khách tối đa',
                      numeric: true,
                      minimum: 1,
                    ),
                    _dialogField(view, 'Hướng nhìn'),
                    TextField(
                      controller: featuredAmenities,
                      decoration: const InputDecoration(
                        labelText: 'Tính năng nổi bật, phân cách bằng dấu phẩy',
                        hintText: 'Ban công, Máy lạnh, WiFi miễn phí',
                      ),
                    ),
                    TextField(
                      controller: amenities,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Tiện nghi, phân cách bằng dấu phẩy',
                        hintText: 'TV, Minibar, Máy sấy tóc',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Hình ảnh phòng (${imageUrls.length + pickedImages.length})',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (imageUrls.isNotEmpty || pickedImages.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...imageUrls.map(
                            (url) => _RoomImageThumbnail(
                              image: CachedNetworkImage(
                                imageUrl: _optimizedRoomImageUrl(
                                  url,
                                  width: 180,
                                ),
                                fit: BoxFit.cover,
                                memCacheWidth: 180,
                                maxWidthDiskCache: 180,
                                fadeInDuration: Duration.zero,
                                placeholder: (_, _) =>
                                    const ColoredBox(color: Color(0xFFE2E8F0)),
                                errorWidget: (_, _, _) => const ColoredBox(
                                  color: Color(0xFFE2E8F0),
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                              ),
                              onRemove: () =>
                                  setDialogState(() => imageUrls.remove(url)),
                            ),
                          ),
                          ...pickedImages.map(
                            (file) => _RoomImageThumbnail(
                              image: FutureBuilder<Uint8List>(
                                future: pickedImageBytes[file],
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Center(
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  }
                                  return Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                    cacheWidth: 180,
                                  );
                                },
                              ),
                              onRemove: () => setDialogState(() {
                                pickedImages.remove(file);
                                pickedImageBytes.remove(file);
                              }),
                            ),
                          ),
                        ],
                      )
                    else
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Chưa chọn ảnh. Có thể chọn tối đa 8 ảnh.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: uploadingImages
                          ? null
                          : () async {
                              try {
                                final remaining =
                                    8 - imageUrls.length - pickedImages.length;
                                if (remaining <= 0) {
                                  ScaffoldMessenger.of(dialogContext)
                                      .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Mỗi hạng phòng chọn tối đa 8 ảnh.',
                                          ),
                                        ),
                                      );
                                  return;
                                }
                                final selected = await imagePicker
                                    .pickMultiImage(
                                      maxWidth: 1280,
                                      maxHeight: 960,
                                      imageQuality: 60,
                                      limit: remaining,
                                    );
                                if (!dialogContext.mounted) return;
                                setDialogState(() {
                                  for (final file in selected.take(remaining)) {
                                    pickedImages.add(file);
                                    pickedImageBytes[file] = file.readAsBytes();
                                  }
                                });
                              } catch (error) {
                                if (!dialogContext.mounted) return;
                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  SnackBar(
                                    content: Text('Không thể chọn ảnh: $error'),
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Chọn ảnh từ thiết bị'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: uploadingImages
                  ? null
                  : () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: uploadingImages
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        uploadingImages = true;
                        uploadedImageCount = 0;
                      });
                      try {
                        final firestore = context.read<FirestoreService>();
                        final imageStorage = ImageStorageService();
                        final roomId =
                            room?['id']?.toString() ??
                            firestore.newPropertyRoomId(propertyId);
                        final uploadedImages = await Future.wait(
                          pickedImages.map((file) async {
                            final url = await imageStorage.uploadRoomImage(
                              propertyId: propertyId,
                              roomId: roomId,
                              image: file,
                              imageBytes: await pickedImageBytes[file]!,
                            );
                            if (dialogContext.mounted) {
                              setDialogState(() => uploadedImageCount++);
                            }
                            return url;
                          }),
                        );
                        final savedImages = [...imageUrls, ...uploadedImages];
                        final data = <String, dynamic>{
                          'name': name.text.trim(),
                          'pricePerNight': int.parse(price.text),
                          'availableCount': int.parse(count.text),
                          'area': int.tryParse(area.text) ?? 0,
                          'bedType': bed.text.trim(),
                          'bedCount': int.parse(bedCount.text),
                          'maxGuests': int.parse(maxGuests.text),
                          'view': view.text.trim(),
                          'image': savedImages.isEmpty ? '' : savedImages.first,
                          'images': savedImages,
                          'featuredAmenities': _splitAmenities(
                            featuredAmenities.text,
                          ),
                          'amenities': _splitAmenities(amenities.text),
                          'isOnSale': room?['isOnSale'] != false,
                        };
                        if (room == null) {
                          await firestore.addPropertyRoom(
                            propertyId: propertyId,
                            roomId: roomId,
                            data: data,
                          );
                        } else {
                          await firestore.updatePropertyRoom(
                            propertyId: propertyId,
                            roomId: roomId,
                            data: data,
                          );
                        }
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } catch (error) {
                        if (dialogContext.mounted) {
                          setDialogState(() => uploadingImages = false);
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text('Không thể lưu phòng: $error'),
                            ),
                          );
                        }
                      }
                    },
              child: uploadingImages
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          pickedImages.isEmpty
                              ? 'Đang lưu...'
                              : 'Đang tải ảnh $uploadedImageCount/'
                                    '${pickedImages.length}...',
                        ),
                      ],
                    )
                  : const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    price.dispose();
    count.dispose();
    area.dispose();
    bed.dispose();
    view.dispose();
    bedCount.dispose();
    maxGuests.dispose();
    featuredAmenities.dispose();
    amenities.dispose();
    if (saved == true && mounted) {
      setState(() {});
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            room == null ? 'Đã thêm hạng phòng.' : 'Đã cập nhật hạng phòng.',
          ),
        ),
      );
    }
  }

  static List<String> _splitAmenities(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  static Widget _dialogField(
    TextEditingController controller,
    String label, {
    bool numeric = false,
    int? minimum,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Vui lòng nhập $label';
          }
          if (numeric) {
            final number = int.tryParse(value);
            if (number == null) return 'Vui lòng nhập số hợp lệ';
            if (minimum != null && number < minimum) {
              return 'Giá trị tối thiểu là $minimum';
            }
          }
          return null;
        },
      ),
    );
  }
}

class _RoomImageThumbnail extends StatelessWidget {
  const _RoomImageThumbnail({required this.image, required this.onRemove});

  final Widget image;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: image),
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              onTap: onRemove,
              child: const CircleAvatar(
                radius: 11,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomOverview extends StatelessWidget {
  const _RoomOverview({required this.rooms});

  final List<Map<String, dynamic>> rooms;

  @override
  Widget build(BuildContext context) {
    final total = rooms.fold<int>(
      0,
      (total, room) => total + _int(room['availableCount']),
    );

    final active = rooms.where((room) => room['isOnSale'] != false).length;

    final percent = rooms.isEmpty ? 0.0 : active / rooms.length * 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Công suất phòng',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 29,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: percent / 100,
            minHeight: 7,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: Colors.white24,
            color: const Color(0xFFFF8A1F),
          ),
          const SizedBox(height: 11),
          Text(
            '$total phòng trống sẵn sàng đón khách',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  static int _int(dynamic value) {
    return (value as num?)?.toInt() ?? 0;
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.onEdit});

  final Map<String, dynamic> room;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    final id = room['id'].toString();

    final propertyId = room['propertyId'].toString();

    final available = (room['availableCount'] as num?)?.toInt() ?? 0;

    final active = room['isOnSale'] != false;

    final price = (room['pricePerNight'] as num?)?.toInt() ?? 0;

    final image = room['image']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (image.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: _optimizedRoomImageUrl(image, width: 900),
                    fit: BoxFit.cover,
                    memCacheWidth: 900,
                    maxWidthDiskCache: 900,
                    fadeInDuration: Duration.zero,
                    placeholder: (_, _) => const ColoredBox(
                      color: Color(0xFFE2E8F0),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (_, _, _) => _fallback(),
                  )
                else
                  _fallback(),

                if (available <= 1)
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        available == 0 ? 'Hết phòng!' : 'Chỉ còn 1 phòng!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room['name']?.toString() ?? 'Hạng phòng',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${room['area'] ?? 0} m² • ${room['bedType'] ?? ''} • ${room['view'] ?? ''}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Giá / đêm',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 9,
                            ),
                          ),
                          Text(
                            '${NumberFormat('#,###', 'vi_VN').format(price)} ₫',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),

                    Switch(
                      value: active,
                      onChanged: (value) async {
                        try {
                          await firestore.setRoomSaleStatus(
                            id,
                            value,
                            propertyId: propertyId,
                          );
                        } on FirebaseException catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Không thể cập nhật trạng thái phòng: ${error.message}',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: const Text('Sửa hạng phòng'),
                      ),
                    ),
                    const SizedBox(width: 7),
                    IconButton(
                      tooltip: 'Xóa hạng phòng',
                      onPressed: () => _deleteRoom(context, room),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRoom(
    BuildContext context,
    Map<String, dynamic> room,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa hạng phòng?'),
        content: Text(
          'Bạn có chắc muốn xóa “${room['name'] ?? 'hạng phòng này'}”?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await context.read<FirestoreService>().deletePropertyRoom(
        propertyId: room['propertyId'].toString(),
        roomId: room['id'].toString(),
      );
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xóa hạng phòng: ${error.message}')),
      );
    }
  }

  static Widget _fallback() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Icon(Icons.bed, size: 50),
    );
  }
}
