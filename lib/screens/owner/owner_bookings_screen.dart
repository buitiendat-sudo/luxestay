import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin_chrome.dart';

class OwnerBookingsScreen extends StatefulWidget {
  const OwnerBookingsScreen({super.key});

  @override
  State<OwnerBookingsScreen> createState() => _OwnerBookingsScreenState();
}

class _OwnerBookingsScreenState extends State<OwnerBookingsScreen> {
  String _statusFilter = 'Tất cả';
  String _query = '';

  static const _filters = [
    'Tất cả',
    'Chờ xác nhận',
    'Đã xác nhận',
    'Đang lưu trú',
    'Hoàn tất',
    'Đã hủy',
  ];

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final auth = context.watch<AuthProvider>();
    if (!auth.isOwner) {
      return const Scaffold(
        body: Center(child: Text('Chỉ chủ khách sạn được quản lý đơn đặt phòng.')),
      );
    }
    final propertyId = auth.propertyId;
    if (propertyId == null || propertyId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Chưa có khách sạn được liên kết.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: const AdminHeader(title: 'Đơn đặt phòng'),
      bottomNavigationBar: const AdminBottomNavigation(selectedIndex: 2),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestore.watchBookingsByProperty(propertyId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Không thể tải đơn đặt phòng: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!;

          final pending = bookings.where((booking) {
            final status = booking['status']?.toString().toLowerCase();

            return status == 'pending' || status == 'waiting';
          }).length;

          final paidRevenue = bookings
              .where(
                (booking) =>
                    booking['paymentStatus']?.toString().toLowerCase() ==
                    'paid',
              )
              .fold<int>(
                0,
                (total, booking) =>
                    total + ((booking['totalPrice'] as num?)?.toInt() ?? 0),
              );
          final visibleBookings = bookings
              .where((booking) {
                final matchesStatus = _matchesFilter(booking, _statusFilter);
                final search = _query.trim().toLowerCase();
                final matchesQuery =
                    search.isEmpty ||
                    [
                      booking['id'],
                      booking['customerName'],
                      booking['userName'],
                      booking['propertyName'],
                    ].any(
                      (value) =>
                          value?.toString().toLowerCase().contains(search) ??
                          false,
                    );
                return matchesStatus && matchesQuery;
              })
              .toList(growable: false);

          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              const Text(
                'Quản lý đơn đặt phòng',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 14),

              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    SizedBox(
                      width: 145,
                      child: AdminKpiCard(
                        title: 'Tổng đơn',
                        value: '${bookings.length}',
                        icon: Icons.add_task_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 145,
                      child: AdminKpiCard(
                        title: 'Chờ xác nhận',
                        value: '$pending',
                        icon: Icons.warning_amber_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 190,
                      child: AdminKpiCard(
                        title: 'Doanh thu đã thu',
                        value: _money(paidRevenue),
                        icon: Icons.payments_outlined,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Tìm mã đơn, khách hoặc cơ sở',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters
                      .map((filter) {
                        final selected = filter == _statusFilter;
                        final count = bookings
                            .where((booking) => _matchesFilter(booking, filter))
                            .length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: ChoiceChip(
                            label: Text('$filter ($count)'),
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => _statusFilter = filter),
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Danh sách đơn (${visibleBookings.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 10),

              if (bookings.isEmpty)
                const AdminEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Chưa có đơn đặt phòng',
                )
              else if (visibleBookings.isEmpty)
                const AdminEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Không tìm thấy đơn phù hợp',
                  description: 'Thử đổi trạng thái hoặc từ khóa tìm kiếm.',
                )
              else
                ...visibleBookings.map(
                  (booking) => _BookingCard(booking: booking),
                ),
            ],
          );
        },
      ),
    );
  }

  static bool _matchesFilter(Map<String, dynamic> booking, String filter) {
    if (filter == 'Tất cả') return true;
    final status = booking['status']?.toString().toLowerCase() ?? 'pending';
    return switch (filter) {
      'Chờ xác nhận' => status == 'pending' || status == 'waiting',
      'Đã xác nhận' => status == 'confirmed',
      'Đang lưu trú' => status == 'checked_in',
      'Hoàn tất' => status == 'checked_out' || status == 'completed',
      'Đã hủy' => status == 'cancelled',
      _ => true,
    };
  }

  static String _money(int value) {
    return '${NumberFormat('#,###', 'vi_VN').format(value)} ₫';
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final Map<String, dynamic> booking;

  @override
  Widget build(BuildContext context) {
    final status = booking['status']?.toString().toLowerCase() ?? 'pending';

    final payment =
        booking['paymentStatus']?.toString().toLowerCase() ?? 'unpaid';

    final id = booking['id']?.toString() ?? '';

    final total = (booking['totalPrice'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            booking['customerName']?.toString() ??
                booking['userName']?.toString() ??
                'Khách LuxeStay',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),

          const SizedBox(height: 3),

          Text(
            booking['propertyName']?.toString() ?? 'LuxeStay Resort',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),

          const Divider(height: 22),

          Row(
            children: [
              Expanded(
                child: _Info(
                  label: 'Số đêm',
                  value: '${booking['totalNights'] ?? 1}',
                ),
              ),
              Expanded(
                child: _Info(
                  label: 'Thanh toán',
                  value: payment == 'paid'
                      ? 'Đã thanh toán'
                      : 'Chưa thanh toán',
                ),
              ),
              Expanded(
                child: _Info(
                  label: 'Tổng tiền',
                  value: '${NumberFormat('#,###', 'vi_VN').format(total)}đ',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              if (status == 'pending' || status == 'waiting')
                Expanded(
                  child: FilledButton(
                    onPressed: id.isEmpty
                        ? null
                        : () => _updateBookingStatus(context, id, 'confirmed'),
                    child: const Text('Xác nhận'),
                  ),
                ),

              if (status == 'pending' || status == 'waiting')
                const SizedBox(width: 7),
              if (status == 'confirmed' || status == 'checked_in')
                Expanded(
                  child: FilledButton(
                    onPressed: id.isEmpty
                        ? null
                        : () => _updateBookingStatus(
                              context,
                              id,
                              status == 'confirmed' ? 'checked_in' : 'checked_out',
                            ),
                    child: Text(
                      status == 'confirmed' ? 'Nhận phòng' : 'Trả phòng',
                    ),
                  ),
                ),
              if (status == 'confirmed' || status == 'checked_in')
                const SizedBox(width: 7),

              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _actions(context, booking);
                  },
                  child: const Text('Thao tác'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> _updateBookingStatus(
    BuildContext context,
    String id,
    String status,
  ) async {
    try {
      await context.read<FirestoreService>().updateBookingStatus(
        bookingId: id,
        status: status,
      );
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể cập nhật đơn: ${error.message}')),
      );
    }
  }

  static void _actions(BuildContext context, Map<String, dynamic> booking) {
    final payment =
        booking['paymentStatus']?.toString().toLowerCase() ?? 'unpaid';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.receipt_long),
                title: const Text('Chi tiết đặt phòng'),
                subtitle: Text(
                  '${booking['roomName'] ?? 'Hạng phòng'} · ${booking['guests'] ?? 1} khách · ${booking['totalNights'] ?? 1} đêm',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showBookingDetails(context, booking);
                },
              ),
              if (payment != 'paid')
                ListTile(
                  leading: const Icon(Icons.verified_outlined),
                  title: const Text('Xác nhận đã thu tiền'),
                  onTap: () async {
                    final bookingId = booking['id']?.toString() ?? '';
                    if (bookingId.isEmpty) return;
                    try {
                      await context
                          .read<FirestoreService>()
                          .updatePaymentStatus(
                            bookingId: bookingId,
                            paymentStatus: 'paid',
                          );
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    } on FirebaseException catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Không thể cập nhật thanh toán: ${error.message}',
                          ),
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  static void _showBookingDetails(
    BuildContext context,
    Map<String, dynamic> booking,
  ) {
    final id = booking['id']?.toString() ?? '';
    final shortId = id.length > 8 ? id.substring(0, 8).toUpperCase() : id;
    final total = (booking['totalPrice'] as num?)?.toInt() ?? 0;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Đơn #$shortId'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailLine(
              'Khách',
              booking['customerName']?.toString() ??
                  booking['userName']?.toString() ??
                  'Khách LuxeStay',
            ),
            _detailLine(
              'Cơ sở',
              booking['propertyName']?.toString() ?? 'LuxeStay Resort',
            ),
            _detailLine('Hạng phòng', booking['roomName']?.toString() ?? '—'),
            _detailLine('Nhận phòng', _dateLabel(booking['checkIn'])),
            _detailLine('Trả phòng', _dateLabel(booking['checkOut'])),
            _detailLine(
              'Thanh toán',
              booking['paymentStatus']?.toString().toLowerCase() == 'paid'
                  ? 'Đã thanh toán'
                  : 'Chưa thanh toán',
            ),
            _detailLine('Tổng tiền', _money(total)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  static Widget _detailLine(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  static String _dateLabel(dynamic value) {
    DateTime? date;
    if (value is DateTime) date = value;
    if (value is Timestamp) date = value.toDate();
    if (value is String) date = DateTime.tryParse(value);
    return date == null
        ? 'Chưa cập nhật'
        : DateFormat('dd/MM/yyyy').format(date);
  }

  static String _money(int value) =>
      '${NumberFormat('#,###', 'vi_VN').format(value)} ₫';
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (status) {
      'pending' || 'waiting' => (
        'Chờ xác nhận',
        const Color(0xFFFFEDD5),
        const Color(0xFFEA580C),
      ),
      'confirmed' => (
        'Đã xác nhận',
        const Color(0xFFDBEAFE),
        const Color(0xFF1D4ED8),
      ),
      'checked_in' => (
        'Đang lưu trú',
        const Color(0xFFDCFCE7),
        const Color(0xFF15803D),
      ),
      'checked_out' || 'completed' => (
        'Hoàn tất',
        const Color(0xFFE0F2FE),
        const Color(0xFF0369A1),
      ),
      'cancelled' => (
        'Đã hủy',
        const Color(0xFFFFE4E6),
        const Color(0xFFBE123C),
      ),
      _ => ('Không xác định', const Color(0xFFF1F5F9), const Color(0xFF475569)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
