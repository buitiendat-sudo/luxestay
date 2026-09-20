import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/property.dart';
import '../../models/room.dart';
import 'booking_screen.dart';

class RoomDetailScreen extends StatelessWidget {
  const RoomDetailScreen({
    super.key,
    required this.property,
    required this.room,
  });

  final Property property;
  final Room room;

  String _formatPrice(int price) {
    return NumberFormat('#,###', 'vi_VN').format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết phòng'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tên resort
            Text(
              property.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),

            const SizedBox(height: 8),

            // Tên phòng
            Text(
              room.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 20),

            // Thông tin chính
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.grey.shade200,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.visibility_outlined,
                      title: 'View',
                      value: room.view.isEmpty
                          ? 'Đang cập nhật'
                          : room.view,
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.square_foot_outlined,
                      title: 'Diện tích',
                      value: '${room.area} m²',
                    ),
                    const Divider(height: 24),
                    _InfoRow(
                      icon: Icons.bed_outlined,
                      title: 'Loại giường',
                      value: room.bedType,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tiện nghi
            Text(
              'Tiện nghi phòng',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 12),

            if (room.amenities.isEmpty)
              Text(
                'Chưa có thông tin tiện nghi.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: room.amenities.map((amenity) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 6),
                        Text(amenity),
                      ],
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 28),

            // Chính sách
            Text(
              'Thông tin đặt phòng',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 12),

            const _PolicyItem(
              icon: Icons.login,
              text: 'Nhận phòng từ 14:00',
            ),

            const _PolicyItem(
              icon: Icons.logout,
              text: 'Trả phòng trước 12:00',
            ),

            const _PolicyItem(
              icon: Icons.cancel_outlined,
              text: 'Chính sách hủy sẽ được hiển thị khi đặt phòng',
            ),

            const SizedBox(height: 24),

            // Giá
            Card(
              elevation: 0,
              color: const Color(0xFFFFF7ED),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Giá phòng / đêm',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_formatPrice(room.pricePerNight)} đ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Nút đặt phòng
      bottomSheet: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(
                      property: property,
                      room: room,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Đặt phòng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFD97706),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PolicyItem extends StatelessWidget {
  const _PolicyItem({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}