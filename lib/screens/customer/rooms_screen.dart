import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/property.dart';
import '../../models/room.dart';
import '../../services/firestore_service.dart';
import 'room_detail_screen.dart';

class RoomsScreen extends StatelessWidget {
  const RoomsScreen({
    super.key,
    required this.property,
  });

  final Property property;

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(property.name),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Room>>(
        stream: firestoreService.getRooms(property.id),
        builder: (context, snapshot) {
          // Đang tải
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Có lỗi
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 50,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Không thể tải danh sách phòng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final rooms = snapshot.data ?? const <Room>[];

          // Không có phòng
          if (rooms.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.hotel_outlined,
                      size: 60,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Resort này chưa có phòng.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // Header
              Text(
                'Phòng tại ${property.name}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 6),

              Text(
                '${rooms.length} loại phòng',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 20),

              // Danh sách phòng
              ...rooms.map(
                (room) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _RoomCard(
                    property: property,
                    room: room,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.property,
    required this.room,
  });

  final Property property;
  final Room room;

  @override
  Widget build(BuildContext context) {
    final amenities = <String>[
      if (room.view.isNotEmpty) room.view,
      ...room.amenities,
    ];

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tên phòng
            Text(
              room.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 16),

            // Thông tin phòng
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _RoomDetail(
                  icon: Icons.square_foot_outlined,
                  text: '${room.area} m²',
                ),
                _RoomDetail(
                  icon: Icons.bed_outlined,
                  text: room.bedType,
                ),
              ],
            ),

            // View
            if (room.view.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 20,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    room.view,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Tiện nghi
            if (amenities.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: amenities.map(
                  (amenity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        amenity,
                        style: const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),

              const SizedBox(height: 18),
            ],

            // Đường phân cách
            Divider(
              color: Colors.grey.shade200,
              height: 1,
            ),

            const SizedBox(height: 16),

            // Giá + nút
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Giá phòng',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatPrice(room.pricePerNight)} đ',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '/ đêm',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Xem chi tiết
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoomDetailScreen(
                          property: property,
                          room: room,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Xem chi tiết',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => '.',
        );
  }
}

class _RoomDetail extends StatelessWidget {
  const _RoomDetail({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: Colors.grey.shade700,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}