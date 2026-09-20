import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../services/firestore_service.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  static const Color _navy = Color(0xFF0F172A);
  static const Color _background = Color(0xFFF8F7F3);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return _ErrorState(
                message:
                    'Không thể tải chuyến đi.\n${snapshot.error}',
              );
            }

            final bookings =
                List<Booking>.from(
              snapshot.data ?? const <Booking>[],
            );

            // Booking mới nhất lên đầu.
            bookings.sort(
              (a, b) {
                final dateA =
                    a.createdAt ?? DateTime(2000);
                final dateB =
                    b.createdAt ?? DateTime(2000);

                return dateB.compareTo(dateA);
              },
            );

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(bookings.length),
                ),

                if (bookings.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyTrips(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      4,
                      16,
                      30,
                    ),
                    sliver: SliverList(
                      delegate:
                          SliverChildBuilderDelegate(
                        (context, index) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 16,
                            ),
                            child: _BookingCard(
                              booking: bookings[index],
                            ),
                          );
                        },
                        childCount: bookings.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int bookingCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        16,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
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
            bookingCount == 0
                ? 'Quản lý các kỳ nghỉ của bạn'
                : '$bookingCount đặt phòng của bạn',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BOOKING CARD
// ============================================================

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
  });

  final Booking booking;

  static const Color _navy = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat(
      'dd/MM/yyyy',
      'vi_VN',
    );

    final moneyFormat = NumberFormat(
      '#,###',
      'vi_VN',
    );

    final status = _BookingStatus.fromValue(
      booking.status,
    );

    final nights = booking.totalNights > 0
        ? booking.totalNights
        : booking.checkOut
            .difference(booking.checkIn)
            .inDays;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ----------------------------------------------------
          // HEADER
          // ----------------------------------------------------

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              12,
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius:
                        BorderRadius.circular(14),
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
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.propertyName.isEmpty
                            ? 'LuxeStay'
                            : booking.propertyName,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _navy,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mã đặt phòng: ${booking.id}',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
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
                borderRadius:
                    BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bed_outlined,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
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
                          overflow:
                              TextOverflow.ellipsis,
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
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _InfoItem(
                    icon: Icons.login_rounded,
                    title: 'Nhận phòng',
                    value:
                        dateFormat.format(
                      booking.checkIn,
                    ),
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
                    value:
                        dateFormat.format(
                      booking.checkOut,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ----------------------------------------------------
          // GUESTS
          // ----------------------------------------------------

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SmallInfo(
                    icon: Icons.people_outline,
                    text:
                        '${booking.guests} khách',
                  ),
                ),
                Expanded(
                  child: _SmallInfo(
                    icon: Icons.hotel_outlined,
                    text:
                        '${booking.rooms} phòng',
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
          // TOTAL
          // ----------------------------------------------------

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tổng thanh toán',
                        style: TextStyle(
                          color:
                              Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${moneyFormat.format(booking.totalPrice)} đ',
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
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
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
              crossAxisAlignment:
                  CrossAxisAlignment.start,
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
  });

  final _BookingStatus status;

  @override
  Widget build(BuildContext context) {
    String text;

    switch (status) {
      case _BookingStatus.pending:
        text = 'Đang xử lý';
        break;
      case _BookingStatus.confirmed:
        text = 'Đã xác nhận';
        break;
      case _BookingStatus.completed:
        text = 'Hoàn thành';
        break;
      case _BookingStatus.cancelled:
        text = 'Đã hủy';
        break;
      case _BookingStatus.unknown:
        text = 'Chi tiết';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY
// ============================================================

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips();

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
                borderRadius:
                    BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.luggage_outlined,
                size: 48,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chưa có chuyến đi',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Các đặt phòng của bạn sẽ xuất hiện ở đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
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
            const Icon(
              Icons.lock_outline_rounded,
              size: 55,
              color: Color(0xFF0F172A),
            ),
            const SizedBox(height: 18),
            const Text(
              'Vui lòng đăng nhập',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đăng nhập để xem và quản lý chuyến đi của bạn.',
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
}

// ============================================================
// ERROR
// ============================================================

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}