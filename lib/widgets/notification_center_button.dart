import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';

class NotificationCenterButton extends StatelessWidget {
  const NotificationCenterButton({super.key, this.iconColor});

  final Color? iconColor;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Thông báo',
    onPressed: () => _showNotifications(context),
    icon: Icon(Icons.notifications_none_rounded, color: iconColor),
  );

  void _showNotifications(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final firestore = context.read<FirestoreService>();
    final owner = auth.isOwner;
    final user = auth.user;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.72,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  owner ? 'Thông báo đặt phòng' : 'Thông báo',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: owner
                    ? _ownerNotifications(firestore, auth.propertyId)
                    : _customerNotifications(firestore, user?.uid),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customerNotifications(FirestoreService firestore, String? userId) {
    if (userId == null) {
      return const Center(child: Text('Đăng nhập để xem thông báo đặt phòng.'));
    }
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firestore.watchBookingsByUser(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _error(snapshot.error);
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final bookings = _newestFirst(snapshot.data!);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            const _NotificationTile(
              icon: Icons.local_offer_outlined,
              color: Color(0xFFD97706),
              title: 'Ưu đãi dành cho bạn',
              message: 'Thành viên mới được giảm 10% cho lần đặt phòng đầu tiên.',
            ),
            const SizedBox(height: 8),
            if (bookings.isEmpty)
              const _NotificationTile(
                icon: Icons.hotel_outlined,
                color: Color(0xFF64748B),
                title: 'Chưa có đặt phòng',
                message: 'Thông báo đặt phòng sẽ xuất hiện tại đây.',
              )
            else
              ...bookings.map((booking) {
                final status = booking['status']?.toString().toLowerCase();
                final successful = status != 'cancelled' && status != 'canceled';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _NotificationTile(
                    icon: successful
                        ? Icons.check_circle_outline_rounded
                        : Icons.event_busy_outlined,
                    color: successful
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB91C1C),
                    title: successful
                        ? 'Đặt phòng thành công'
                        : 'Đặt phòng đã hủy',
                    message:
                        '${booking['propertyName'] ?? 'Khách sạn'} · ${booking['roomName'] ?? 'Phòng'}',
                    date: _dateLabel(booking['createdAt']),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _ownerNotifications(FirestoreService firestore, String? propertyId) {
    if (propertyId == null || propertyId.isEmpty) {
      return const Center(child: Text('Tài khoản chưa liên kết khách sạn.'));
    }
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firestore.watchBookingsByProperty(propertyId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _error(snapshot.error);
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final bookings = _newestFirst(snapshot.data!);
        if (bookings.isEmpty) {
          return const Center(child: Text('Chưa có đơn đặt phòng mới.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            final status = booking['status']?.toString() ?? 'pending';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _NotificationTile(
                icon: Icons.notifications_active_outlined,
                color: const Color(0xFFD97706),
                title: 'Đơn đặt phòng ${_statusLabel(status)}',
                message:
                    '${booking['customerName'] ?? booking['userName'] ?? 'Khách hàng'} · ${booking['roomName'] ?? 'Phòng'}',
                date: _dateLabel(booking['createdAt']),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _error(Object? error) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text('Không thể tải thông báo: $error', textAlign: TextAlign.center),
    ),
  );

  static List<Map<String, dynamic>> _newestFirst(
    List<Map<String, dynamic>> bookings,
  ) {
    final sorted = [...bookings];
    sorted.sort(
      (a, b) => _readDate(b['createdAt']).compareTo(_readDate(a['createdAt'])),
    );
    return sorted.take(30).toList(growable: false);
  }

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _dateLabel(dynamic value) {
    final date = _readDate(value);
    if (date.millisecondsSinceEpoch == 0) return '';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'đã xác nhận';
      case 'cancelled':
      case 'canceled':
        return 'đã hủy';
      case 'checked_in':
        return 'đang lưu trú';
      case 'completed':
        return 'đã hoàn tất';
      default:
        return 'mới';
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.date = '',
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String date;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(message),
      trailing: date.isEmpty ? null : Text(date, style: const TextStyle(fontSize: 11)),
    ),
  );
}