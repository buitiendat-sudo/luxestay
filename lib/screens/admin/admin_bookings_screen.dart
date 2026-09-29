import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/firestore_service.dart';
import '../../widgets/admin_chrome.dart';
import 'admin_hotels_screen.dart';
import 'admin_rooms_screen.dart';
import 'admin_users_screen.dart';

class AdminBookingsScreen
    extends StatelessWidget {
  const AdminBookingsScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final firestore =
        context.read<FirestoreService>();

    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F7FB),
      appBar: const AdminHeader(
        title: 'Đơn đặt phòng',
      ),
      bottomNavigationBar:
          AdminBottomNavigation(
        selectedIndex: 2,
        onSelected: (index) {
          if (index == 2) return;

          final page = switch (index) {
            0 =>
              const AdminHotelsScreen(),
            1 =>
              const AdminRoomsScreen(),
            _ =>
              const AdminUsersScreen(),
          };

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => page,
            ),
          );
        },
      ),
      body: StreamBuilder<
          List<Map<String, dynamic>>>(
        stream:
            firestore.watchBookings(),
        builder: (
          context,
          snapshot,
        ) {
          if (!snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          final bookings =
              snapshot.data!;

          final pending =
              bookings.where(
            (booking) {
              final status =
                  booking['status']
                      ?.toString()
                      .toLowerCase();

              return status ==
                      'pending' ||
                  status == 'waiting';
            },
          ).length;

          final revenue =
              bookings.fold<int>(
            0,
            (total, booking) =>
                total +
                ((booking['totalPrice']
                            as num?)
                        ?.toInt() ??
                    0),
          );

          return ListView(
            padding:
                const EdgeInsets.all(14),
            children: [
              const Text(
                'Vận hành hôm nay',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection:
                      Axis.horizontal,
                  children: [
                    SizedBox(
                      width: 145,
                      child: AdminKpiCard(
                        title: 'Đơn mới',
                        value:
                            '${bookings.length}',
                        icon: Icons
                            .add_task_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 145,
                      child: AdminKpiCard(
                        title:
                            'Cần xử lý',
                        value: '$pending',
                        icon: Icons
                            .warning_amber_rounded,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 190,
                      child: AdminKpiCard(
                        title:
                            'Tổng giá trị đơn',
                        value:
                            _money(revenue),
                        icon: Icons
                            .payments_outlined,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              Text(
                'Danh sách đơn (${bookings.length})',
                style:
                    const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              if (bookings.isEmpty)
                const Center(
                  child: Padding(
                    padding:
                        EdgeInsets.all(
                      40,
                    ),
                    child: Text(
                      'Chưa có đơn đặt phòng.',
                    ),
                  ),
                )
              else
                ...bookings.map(
                  (booking) =>
                      _BookingCard(
                    booking: booking,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _money(int value) {
    return '${NumberFormat('#,###', 'vi_VN').format(value)} ₫';
  }
}

class _BookingCard
    extends StatelessWidget {
  const _BookingCard({
    required this.booking,
  });

  final Map<String, dynamic> booking;

  @override
  Widget build(BuildContext context) {
    final status =
        booking['status']
                ?.toString()
                .toLowerCase() ??
            'pending';

    final payment =
        booking['paymentStatus']
                ?.toString()
                .toLowerCase() ??
            'unpaid';

    final id =
        booking['id'].toString();

    final total =
        (booking['totalPrice']
                    as num?)
                ?.toInt() ??
            0;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color:
              const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase()}',
                  style:
                      const TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
              _StatusBadge(
                status: status,
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            booking['customerName']
                    ?.toString() ??
                booking['userName']
                    ?.toString() ??
                'Khách LuxeStay',
            style: const TextStyle(
              fontSize: 16,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            booking['propertyName']
                    ?.toString() ??
                'LuxeStay Resort',
            style: const TextStyle(
              color:
                  Color(0xFF64748B),
              fontSize: 11,
            ),
          ),

          const Divider(height: 22),

          Row(
            children: [
              Expanded(
                child: _Info(
                  label: 'Số đêm',
                  value:
                      '${booking['totalNights'] ?? 1}',
                ),
              ),
              Expanded(
                child: _Info(
                  label:
                      'Thanh toán',
                  value: payment ==
                          'paid'
                      ? 'Đã thanh toán'
                      : 'Chưa thanh toán',
                ),
              ),
              Expanded(
                child: _Info(
                  label: 'Tổng tiền',
                  value:
                      '${NumberFormat('#,###', 'vi_VN').format(total)}đ',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              if (status == 'pending')
                Expanded(
                  child:
                      FilledButton(
                    onPressed: () {
                      context
                          .read<
                              FirestoreService>()
                          .updateBookingStatus(
                            bookingId:
                                id,
                            status:
                                'confirmed',
                          );
                    },
                    child:
                        const Text(
                      'Xác nhận',
                    ),
                  ),
                ),

              if (status == 'pending')
                const SizedBox(
                  width: 7,
                ),

              Expanded(
                child:
                    OutlinedButton(
                  onPressed: () {
                    _actions(
                      context,
                      booking,
                    );
                  },
                  child:
                      const Text(
                    'Thao tác',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static void _actions(
    BuildContext context,
    Map<String, dynamic> booking,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              const ListTile(
                leading: Icon(
                  Icons.receipt_long,
                ),
                title:
                    Text('Xem hóa đơn'),
              ),
              ListTile(
                leading: const Icon(
                  Icons
                      .verified_outlined,
                ),
                title: const Text(
                  'Duyệt tiền cọc',
                ),
                onTap: () async {
                  await context
                      .read<
                          FirestoreService>()
                      .updatePaymentStatus(
                        bookingId:
                            booking['id']
                                .toString(),
                        paymentStatus:
                            'paid',
                      );

                  if (sheetContext
                      .mounted) {
                    Navigator.pop(
                      sheetContext,
                    );
                  }
                },
              ),
              const ListTile(
                leading: Icon(
                  Icons
                      .calendar_month,
                ),
                title:
                    Text('Đổi lịch'),
              ),
              const ListTile(
                leading: Icon(
                  Icons
                      .currency_exchange,
                ),
                title:
                    Text('Hoàn tiền'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color:
                Color(0xFF94A3B8),
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge
    extends StatelessWidget {
  const _StatusBadge({
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final confirmed =
        status == 'confirmed';

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: confirmed
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFFEDD5),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Text(
        confirmed
            ? 'Đã xác nhận'
            : 'Chờ xử lý',
        style: TextStyle(
          color: confirmed
              ? const Color(0xFF15803D)
              : const Color(0xFFEA580C),
          fontSize: 9,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }
}