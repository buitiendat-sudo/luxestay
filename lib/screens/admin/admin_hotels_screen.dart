import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/firestore_service.dart';
import '../../widgets/admin_chrome.dart';
import 'admin_bookings_screen.dart';
import 'admin_rooms_screen.dart';
import 'admin_users_screen.dart';

class AdminHotelsScreen
    extends StatelessWidget {
  const AdminHotelsScreen({
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
        title: 'Quản lý Khách sạn',
      ),
      bottomNavigationBar:
          AdminBottomNavigation(
        selectedIndex: 0,
        onSelected: (index) {
          if (index == 0) return;

          final page = switch (index) {
            1 =>
              const AdminRoomsScreen(),
            2 =>
              const AdminBookingsScreen(),
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
            firestore.watchProperties(),
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

          final hotels =
              snapshot.data!;

          final averageRating =
              _averageRating(hotels);

          final revenue =
              hotels.fold<int>(
            0,
            (total, hotel) =>
                total +
                _toInt(
                  hotel[
                      'monthlyRevenue'],
                ),
          );

          final occupancy =
              _averageOccupancy(
            hotels,
          );

          return ListView(
            padding:
                const EdgeInsets.all(14),
            children: [
              const Text(
                'Tổng quan hệ thống',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Theo dõi các cơ sở LuxeStay trong thời gian thực.',
                style: TextStyle(
                  color:
                      Color(0xFF64748B),
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                height: 122,
                child: ListView(
                  scrollDirection:
                      Axis.horizontal,
                  children: [
                    SizedBox(
                      width: 145,
                      child: AdminKpiCard(
                        title:
                            'Cơ sở trực thuộc',
                        value:
                            '${hotels.length}',
                        icon: Icons
                            .apartment_outlined,
                      ),
                    ),
                    const SizedBox(width: 9),
                    SizedBox(
                      width: 145,
                      child: AdminKpiCard(
                        title:
                            'Tỷ lệ lấp đầy',
                        value:
                            '${occupancy.toStringAsFixed(1)}%',
                        icon: Icons
                            .donut_large_outlined,
                      ),
                    ),
                    const SizedBox(width: 9),
                    SizedBox(
                      width: 145,
                      child: AdminKpiCard(
                        title: 'Đánh giá',
                        value:
                            '${averageRating.toStringAsFixed(2)}/5',
                        icon:
                            Icons.star_outline,
                      ),
                    ),
                    const SizedBox(width: 9),
                    SizedBox(
                      width: 170,
                      child: AdminKpiCard(
                        title:
                            'Doanh thu tháng',
                        value:
                            _money(revenue),
                        icon: Icons
                            .payments_outlined,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Danh sách cơ sở',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${hotels.length} cơ sở',
                    style:
                        const TextStyle(
                      color:
                          Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (hotels.isEmpty)
                const _EmptyHotel()
              else
                ...hotels.map(
                  (hotel) =>
                      _HotelCard(
                    hotel: hotel,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static int _toInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static double _averageRating(
    List<Map<String, dynamic>>
        hotels,
  ) {
    if (hotels.isEmpty) return 0;

    var total = 0.0;

    for (final hotel in hotels) {
      total +=
          (hotel['rating'] as num?)
                  ?.toDouble() ??
              0;
    }

    return total / hotels.length;
  }

  static double _averageOccupancy(
    List<Map<String, dynamic>>
        hotels,
  ) {
    if (hotels.isEmpty) return 0;

    var total = 0.0;

    for (final hotel in hotels) {
      total +=
          (hotel['occupancyRate']
                      as num?)
                  ?.toDouble() ??
              0;
    }

    return total / hotels.length;
  }

  static String _money(int value) {
    return '${NumberFormat('#,###', 'vi_VN').format(value)} ₫';
  }
}

class _HotelCard extends StatelessWidget {
  const _HotelCard({
    required this.hotel,
  });

  final Map<String, dynamic> hotel;

  @override
  Widget build(BuildContext context) {
    final firestore =
        context.read<FirestoreService>();

    final id =
        hotel['id']?.toString() ?? '';

    final image =
        hotel['image']?.toString() ??
            '';

    final active =
        hotel['isActive'] != false;

    final rating =
        (hotel['rating'] as num?)
                ?.toDouble() ??
            0;

    final occupancy =
        (hotel['occupancyRate']
                    as num?)
                ?.toDouble() ??
            0;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              const Color(0xFFE5E7EB),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 165,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (image.isNotEmpty)
                  Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, _, _) =>
                            _fallback(),
                  )
                else
                  _fallback(),

                const DecoratedBox(
                  decoration:
                      BoxDecoration(
                    gradient:
                        LinearGradient(
                      begin: Alignment
                          .topCenter,
                      end: Alignment
                          .bottomCenter,
                      colors: [
                        Colors
                            .transparent,
                        Color(
                          0xAA000000,
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration:
                        BoxDecoration(
                      color: active
                          ? const Color(
                              0xFFDCFCE7,
                            )
                          : const Color(
                              0xFFFEE2E2,
                            ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        20,
                      ),
                    ),
                    child: Text(
                      active
                          ? 'Đang hoạt động'
                          : 'Tạm dừng',
                      style: TextStyle(
                        color: active
                            ? const Color(
                                0xFF15803D,
                              )
                            : const Color(
                                0xFFDC2626,
                              ),
                        fontSize: 9,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 11,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        hotel['name']
                                ?.toString() ??
                            'LuxeStay Resort',
                        style:
                            const TextStyle(
                          color:
                              Colors.white,
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                      const SizedBox(
                        height: 2,
                      ),
                      Text(
                        hotel['location']
                                ?.toString() ??
                            '',
                        style:
                            const TextStyle(
                          color:
                              Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding:
                const EdgeInsets.all(
              12,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child:
                          _HotelMetric(
                        label:
                            'Công suất',
                        value:
                            '${occupancy.toStringAsFixed(1)}%',
                      ),
                    ),
                    Expanded(
                      child:
                          _HotelMetric(
                        label:
                            'Phân hạng',
                        value:
                            '${rating.toStringAsFixed(1)} ★',
                      ),
                    ),
                    Expanded(
                      child:
                          _HotelMetric(
                        label:
                            'Giá từ',
                        value:
                            _shortPrice(
                          hotel[
                              'pricePerNight'],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 11,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                          OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger
                              .of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Mở màn điều phối phòng.',
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Điều phối',
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 6,
                    ),
                    Expanded(
                      child:
                          OutlinedButton(
                        onPressed: () {},
                        child:
                            const Text(
                          'Sửa',
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 6,
                    ),
                    Expanded(
                      child:
                          FilledButton(
                        onPressed:
                            id.isEmpty
                                ? null
                                : () {
                                    firestore
                                        .setPropertyActiveStatus(
                                      id,
                                      !active,
                                    );
                                  },
                        style:
                            FilledButton
                                .styleFrom(
                          backgroundColor:
                              active
                                  ? const Color(
                                      0xFF111827,
                                    )
                                  : const Color(
                                      0xFF059669,
                                    ),
                        ),
                        child: Text(
                          active
                              ? 'Tạm dừng'
                              : 'Mở lại',
                          style:
                              const TextStyle(
                            fontSize: 10,
                          ),
                        ),
                      ),
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

  static Widget _fallback() {
    return Container(
      color:
          const Color(0xFFE2E8F0),
      child: const Icon(
        Icons.apartment,
        size: 50,
      ),
    );
  }

  static String _shortPrice(
    dynamic value,
  ) {
    final number =
        (value as num?)?.toInt() ??
            0;

    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}tr';
    }

    return NumberFormat.compact(
      locale: 'vi',
    ).format(number);
  }
}

class _HotelMetric
    extends StatelessWidget {
  const _HotelMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
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
          style: const TextStyle(
            color:
                Color(0xFF111827),
            fontSize: 12,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyHotel
    extends StatelessWidget {
  const _EmptyHotel();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Text(
          'Chưa có cơ sở.',
        ),
      ),
    );
  }
}