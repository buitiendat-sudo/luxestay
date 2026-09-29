import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../auth/login_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  static const Color _navy = Color(0xFF0F172A);
  static const Color _background = Color(0xFFF8F7F3);

  String _selectedFilter = 'all';

  final List<({String key, String label})> _filters = const [
    (key: 'all', label: 'Tất cả'),
    (key: 'pending', label: 'Chờ xác nhận'),
    (key: 'confirmed', label: 'Đã xác nhận'),
    (key: 'completed', label: 'Hoàn thành'),
    (key: 'cancelled', label: 'Đã hủy'),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user ?? FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: _background,
        body: _LoginRequiredState(),
      );
    }

    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: StreamBuilder<List<Booking>>(
          stream: firestoreService.getBookingsForUser(
            user.uid,
            userEmail: user.email,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: _navy,
                ),
              );
            }

            if (snapshot.hasError) {
              return _ErrorState(
                message: 'Không thể tải danh sách chuyến đi.\n${snapshot.error}',
                onRetry: () => setState(() {}),
              );
            }

            final allBookings = List<Booking>.from(
              snapshot.data ?? const <Booking>[],
            );

            // Sắp xếp booking mới nhất lên đầu.
            allBookings.sort((a, b) {
              final dateA = a.createdAt ?? a.checkIn;
              final dateB = b.createdAt ?? b.checkIn;
              return dateB.compareTo(dateA);
            });

            // Lọc theo trạng thái đã chọn
            final filteredBookings = _selectedFilter == 'all'
                ? allBookings
                : allBookings.where((booking) {
                    final status = _BookingStatus.fromValue(booking.status);
                    return status.name == _selectedFilter;
                  }).toList();

            return RefreshIndicator(
              color: _navy,
              onRefresh: () async {
                setState(() {});
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeader(allBookings),
                  ),
                  SliverToBoxAdapter(
                    child: _buildFilterTabs(allBookings),
                  ),
                  if (filteredBookings.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyTrips(
                        isFiltered: _selectedFilter != 'all',
                        onResetFilter: () {
                          setState(() {
                            _selectedFilter = 'all';
                          });
                        },
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _BookingCard(
                                booking: filteredBookings[index],
                                onTap: () => _showBookingDetails(
                                  context,
                                  filteredBookings[index],
                                ),
                                onCancel: () => _confirmCancelBooking(
                                  context,
                                  filteredBookings[index],
                                ),
                              ),
                            );
                          },
                          childCount: filteredBookings.length,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(List<Booking> bookings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chuyến đi',
            style: TextStyle(
              color: _navy,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            bookings.isEmpty
                ? 'Quản lý các kỳ nghỉ của bạn'
                : '${bookings.length} đặt phòng của bạn',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(List<Booking> allBookings) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter.key;

          int count;
          if (filter.key == 'all') {
            count = allBookings.length;
          } else {
            count = allBookings.where((b) {
              return _BookingStatus.fromValue(b.status).name == filter.key;
            }).length;
          }

          return ChoiceChip(
            label: Text(
              count > 0 ? '${filter.label} ($count)' : filter.label,
              style: TextStyle(
                color: isSelected ? Colors.white : _navy,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedFilter = filter.key;
                });
              }
            },
            selectedColor: _navy,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected ? _navy : Colors.grey.shade300,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  void _showBookingDetails(BuildContext context, Booking booking) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _BookingDetailModal(
        booking: booking,
        onCancel: () {
          Navigator.pop(sheetContext);
          _confirmCancelBooking(context, booking);
        },
      ),
    );
  }

  Future<void> _confirmCancelBooking(
    BuildContext context,
    Booking booking,
  ) async {
    final status = _BookingStatus.fromValue(booking.status);
    if (status == _BookingStatus.cancelled ||
        status == _BookingStatus.completed) {
      return;
    }

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFDC2626),
                size: 26,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hủy đặt phòng?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'Bạn có chắc chắn muốn hủy đặt phòng này? Hành động này sẽ cập nhật trạng thái đơn đặt phòng thành "Đã hủy".',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Giữ lại',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xác nhận hủy'),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true || !context.mounted) return;

    try {
      final firestoreService = context.read<FirestoreService>();
      await firestoreService.updateBooking(booking.id, {
        'status': 'cancelled',
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã hủy đặt phòng thành công.'),
          backgroundColor: Color(0xFF0F172A),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hủy đặt phòng thất bại: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

// ============================================================
// BOOKING CARD
// ============================================================

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onTap,
    required this.onCancel,
  });

  final Booking booking;
  final VoidCallback onTap;
  final VoidCallback onCancel;

  static const Color _navy = Color(0xFF0F172A);

  String _formatPrice(int amount) {
    try {
      final formatter = NumberFormat('#,###', 'vi_VN');
      return '${formatter.format(amount)} đ';
    } catch (_) {
      return '$amount đ';
    }
  }

  String _formatDate(DateTime date) {
    try {
      final formatter = DateFormat('dd/MM/yyyy');
      return formatter.format(date);
    } catch (_) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _BookingStatus.fromValue(booking.status);

    final rawNights = booking.totalNights > 0
        ? booking.totalNights
        : booking.checkOut.difference(booking.checkIn).inDays;
    final nights = rawNights > 0 ? rawNights : 1;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------
              // HEADER
              // ----------------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.hotel_rounded,
                        color: _navy,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.propertyName.isEmpty
                                ? 'LuxeStay'
                                : booking.propertyName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mã đặt: ${booking.id.length > 12 ? '${booking.id.substring(0, 12)}...' : booking.id}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusBadge(status: status),
                  ],
                ),
              ),

              const Divider(height: 1),

              // ----------------------------------------------------
              // ROOM
              // ----------------------------------------------------
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.bed_outlined,
                          color: _navy,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Phòng',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              booking.roomName.isEmpty
                                  ? 'Phòng đã đặt'
                                  : booking.roomName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ----------------------------------------------------
              // DATE
              // ----------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.login_rounded,
                        title: 'Nhận phòng',
                        value: _formatDate(booking.checkIn),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 38,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.logout_rounded,
                        title: 'Trả phòng',
                        value: _formatDate(booking.checkOut),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ----------------------------------------------------
              // GUESTS & ROOMS
              // ----------------------------------------------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _SmallInfo(
                        icon: Icons.people_outline,
                        text: '${booking.guests} khách',
                      ),
                    ),
                    Expanded(
                      child: _SmallInfo(
                        icon: Icons.hotel_outlined,
                        text: '${booking.rooms} phòng',
                      ),
                    ),
                    Expanded(
                      child: _SmallInfo(
                        icon: Icons.nightlight_outlined,
                        text: '$nights đêm',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              const Divider(height: 1),

              // ----------------------------------------------------
              // TOTAL & ACTION
              // ----------------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tổng thanh toán',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _formatPrice(booking.totalPrice),
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _BookingActionButton(
                      status: status,
                      onTap: onTap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BOOKING DETAIL MODAL
// ============================================================

class _BookingDetailModal extends StatelessWidget {
  const _BookingDetailModal({
    required this.booking,
    required this.onCancel,
  });

  final Booking booking;
  final VoidCallback onCancel;

  static const Color _navy = Color(0xFF0F172A);
  static const Color _gold = Color(0xFFD97706);

  String _formatPrice(int amount) {
    try {
      final formatter = NumberFormat('#,###', 'vi_VN');
      return '${formatter.format(amount)} đ';
    } catch (_) {
      return '$amount đ';
    }
  }

  String _formatDate(DateTime date) {
    try {
      final formatter = DateFormat('dd/MM/yyyy');
      return formatter.format(date);
    } catch (_) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _BookingStatus.fromValue(booking.status);
    final canCancel = status == _BookingStatus.pending ||
        status == _BookingStatus.confirmed;

    final rawNights = booking.totalNights > 0
        ? booking.totalNights
        : booking.checkOut.difference(booking.checkIn).inDays;
    final nights = rawNights > 0 ? rawNights : 1;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Title & Status
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.propertyName.isEmpty
                          ? 'LuxeStay'
                          : booking.propertyName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.roomName.isEmpty
                          ? 'Phòng đã đặt'
                          : booking.roomName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Booking Code with copy button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.confirmation_number_outlined,
                  size: 20,
                  color: _navy,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mã đặt phòng',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      SelectableText(
                        booking.id,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _navy,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  tooltip: 'Sao chép mã',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: booking.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép mã đặt phòng.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Checkin - Checkout
          Row(
            children: [
              Expanded(
                child: _ModalInfoCard(
                  icon: Icons.login_rounded,
                  title: 'Nhận phòng',
                  value: _formatDate(booking.checkIn),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModalInfoCard(
                  icon: Icons.logout_rounded,
                  title: 'Trả phòng',
                  value: _formatDate(booking.checkOut),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Guests & Rooms
          Row(
            children: [
              Expanded(
                child: _ModalInfoCard(
                  icon: Icons.people_outline,
                  title: 'Khách',
                  value: '${booking.guests} người',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModalInfoCard(
                  icon: Icons.hotel_outlined,
                  title: 'Số phòng',
                  value: '${booking.rooms} phòng',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ModalInfoCard(
                  icon: Icons.nightlight_outlined,
                  title: 'Lưu trú',
                  value: '$nights đêm',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Price Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Giá mỗi đêm:',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              Text(
                _formatPrice(booking.pricePerNight),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán:',
                style: TextStyle(
                  color: _navy,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatPrice(booking.totalPrice),
                style: const TextStyle(
                  color: _gold,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Cancel button if applicable
          if (canCancel)
            FilledButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text(
                'Hủy đặt phòng',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModalInfoCard extends StatelessWidget {
  const _ModalInfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF0F172A)),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// INFO ITEM
// ============================================================

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF0F172A),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SMALL INFO
// ============================================================

class _SmallInfo extends StatelessWidget {
  const _SmallInfo({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 17,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STATUS
// ============================================================

enum _BookingStatus {
  pending,
  confirmed,
  completed,
  cancelled,
  unknown;

  static _BookingStatus fromValue(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return _BookingStatus.pending;
      case 'confirmed':
      case 'approved':
        return _BookingStatus.confirmed;
      case 'completed':
      case 'done':
        return _BookingStatus.completed;
      case 'cancelled':
      case 'canceled':
        return _BookingStatus.cancelled;
      default:
        return _BookingStatus.unknown;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.status,
  });

  final _BookingStatus status;

  @override
  Widget build(BuildContext context) {
    late String label;
    late Color background;
    late Color foreground;

    switch (status) {
      case _BookingStatus.pending:
        label = 'Chờ xác nhận';
        background = const Color(0xFFFFF7ED);
        foreground = const Color(0xFFC2410C);
        break;

      case _BookingStatus.confirmed:
        label = 'Đã xác nhận';
        background = const Color(0xFFECFDF5);
        foreground = const Color(0xFF047857);
        break;

      case _BookingStatus.completed:
        label = 'Hoàn thành';
        background = const Color(0xFFEFF6FF);
        foreground = const Color(0xFF1D4ED8);
        break;

      case _BookingStatus.cancelled:
        label = 'Đã hủy';
        background = const Color(0xFFFEF2F2);
        foreground = const Color(0xFFB91C1C);
        break;

      case _BookingStatus.unknown:
        label = 'Đang xử lý';
        background = const Color(0xFFF1F5F9);
        foreground = const Color(0xFF475569);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ============================================================
// ACTION BUTTON
// ============================================================

class _BookingActionButton extends StatelessWidget {
  const _BookingActionButton({
    required this.status,
    required this.onTap,
  });

  final _BookingStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    String text;
    Color textColor = const Color(0xFF0F172A);

    switch (status) {
      case _BookingStatus.pending:
      case _BookingStatus.confirmed:
        text = 'Chi tiết';
        break;
      case _BookingStatus.completed:
        text = 'Đã xong';
        textColor = Colors.grey.shade600;
        break;
      case _BookingStatus.cancelled:
        text = 'Đã hủy';
        textColor = const Color(0xFFB91C1C);
        break;
      case _BookingStatus.unknown:
        text = 'Chi tiết';
        break;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY
// ============================================================

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips({
    this.isFiltered = false,
    this.onResetFilter,
  });

  final bool isFiltered;
  final VoidCallback? onResetFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.luggage_outlined,
                size: 48,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isFiltered
                  ? 'Không tìm thấy chuyến đi'
                  : 'Chưa có chuyến đi nào',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Không có đặt phòng nào trong mục này.'
                  : 'Các đặt phòng của bạn sẽ xuất hiện ở đây sau khi bạn đặt phòng thành công.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (isFiltered && onResetFilter != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onResetFilter,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFF0F172A)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Xem tất cả chuyến đi'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LOGIN REQUIRED
// ============================================================

class _LoginRequiredState extends StatelessWidget {
  const _LoginRequiredState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 42,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Vui lòng đăng nhập',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đăng nhập để xem và quản lý các chuyến đi của bạn.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Đăng nhập ngay',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ERROR
// ============================================================

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 14),
            const Text(
              'Không thể tải dữ liệu',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Thử lại'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}