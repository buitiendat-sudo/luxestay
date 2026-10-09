import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/firestore_service.dart';
import '../../widgets/admin_chrome.dart';
import '../../widgets/revenue_chart.dart';

const _ink = Color(0xFF111827);
const _muted = Color(0xFF758096);
const _canvas = Color(0xFFF6F7FE);
const _orange = Color(0xFFFF922B);
const _blue = Color(0xFFE5EDFF);
const _green = Color(0xFF35D6A0);

String checkInStatusTransition(String status) {
  final normalized = status.toLowerCase();

  if (normalized == 'pending' || normalized == 'waiting') {
    return 'confirmed';
  }

  if (normalized == 'confirmed') {
    return 'checked_in';
  }

  return normalized;
}

String checkOutStatusTransition(String status) {
  final normalized = status.toLowerCase();

  if (normalized == 'checked_in') {
    return 'checked_out';
  }

  if (normalized == 'checked_out') {
    return 'completed';
  }

  return normalized;
}

class PropertyRevenueRank {
  const PropertyRevenueRank({
    required this.propertyId,
    required this.propertyName,
    required this.revenue,
  });

  final String propertyId;
  final String propertyName;
  final int revenue;
}

List<PropertyRevenueRank> rankPropertiesByRevenue({
  required List<Map<String, dynamic>> properties,
  required List<Map<String, dynamic>> bookings,
  required DateTime today,
  required String period,
}) {
  final day = DateUtils.dateOnly(today);
  final start = switch (period) {
    'Tháng này' => DateTime(today.year, today.month),
    'Hôm nay' => day,
    _ => day.subtract(Duration(days: day.weekday - 1)),
  };
  final end = switch (period) {
    'Tháng này' => DateTime(today.year, today.month + 1),
    'Hôm nay' => start.add(const Duration(days: 1)),
    _ => start.add(const Duration(days: 7)),
  };
  final revenueByProperty = <String, int>{};

  for (final booking in bookings) {
    if (booking['paymentStatus']?.toString().toLowerCase() != 'paid') {
      continue;
    }

    final date =
        _readDate(booking['createdAt']) ?? _readDate(booking['checkIn']);
    if (date == null || date.isBefore(start) || !date.isBefore(end)) continue;

    final propertyId = booking['propertyId']?.toString() ?? '';
    if (propertyId.isEmpty) continue;

    revenueByProperty.update(
      propertyId,
      (revenue) => revenue + _asInt(booking['totalPrice']),
      ifAbsent: () => _asInt(booking['totalPrice']),
    );
  }

  final rankings = properties
      .map((property) {
        final propertyId = property['id']?.toString() ?? '';
        return PropertyRevenueRank(
          propertyId: propertyId,
          propertyName: property['name']?.toString() ?? 'Cơ sở LuxeStay',
          revenue: revenueByProperty[propertyId] ?? 0,
        );
      })
      .where((rank) => rank.propertyId.isNotEmpty && rank.revenue > 0)
      .toList();

  rankings.sort((a, b) {
    final revenueOrder = b.revenue.compareTo(a.revenue);
    return revenueOrder != 0
        ? revenueOrder
        : a.propertyName.toLowerCase().compareTo(b.propertyName.toLowerCase());
  });

  return rankings.take(3).toList(growable: false);
}

class RevenueTrendPoint {
  const RevenueTrendPoint({required this.label, required this.revenue});

  final String label;
  final int revenue;
}

List<RevenueTrendPoint> revenueTrendPoints({
  required List<Map<String, dynamic>> bookings,
  required DateTime today,
  required String period,
}) {
  late final List<String> labels;
  late final List<bool Function(DateTime)> matchesPeriod;

  if (period == 'Hôm nay') {
    labels = const ['00', '04', '08', '12', '16', '20'];
    matchesPeriod = List.generate(
      6,
      (index) =>
          (date) => DateUtils.isSameDay(date, today) && date.hour ~/ 4 == index,
    );
  } else if (period == 'Tuần này') {
    final weekStart = DateUtils.dateOnly(today)
        .subtract(Duration(days: today.weekday - 1));
    labels = const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    matchesPeriod = List.generate(
      7,
      (index) =>
          (date) =>
              DateUtils.isSameDay(date, weekStart.add(Duration(days: index))),
    );
  } else {
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    final bucketCount = (daysInMonth + 6) ~/ 7;
    labels = List.generate(bucketCount, (index) {
      final firstDay = index * 7 + 1;
      final lastDay = (firstDay + 6).clamp(1, daysInMonth);
      return '$firstDay-$lastDay';
    });
    matchesPeriod = List.generate(
      bucketCount,
      (index) =>
          (date) =>
              date.year == today.year &&
              date.month == today.month &&
              (date.day - 1) ~/ 7 == index,
    );
  }

  final totals = List<int>.filled(labels.length, 0);
  for (final booking in bookings) {
    if (booking['paymentStatus']?.toString().toLowerCase() != 'paid') {
      continue;
    }

    final date =
        _readDate(booking['createdAt']) ?? _readDate(booking['checkIn']);
    if (date == null) continue;

    for (var index = 0; index < matchesPeriod.length; index++) {
      if (matchesPeriod[index](date)) {
        totals[index] += _asInt(booking['totalPrice']);
        break;
      }
    }
  }

  return List.generate(
    labels.length,
    (index) => RevenueTrendPoint(label: labels[index], revenue: totals[index]),
    growable: false,
  );
}

class AdminRoomMapScreen extends StatefulWidget {
  const AdminRoomMapScreen({super.key});

  @override
  State<AdminRoomMapScreen> createState() => _AdminRoomMapScreenState();
}

class _AdminRoomMapScreenState extends State<AdminRoomMapScreen> {
  String? _propertyId;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: _canvas,
      appBar: const AdminHeader(title: 'Sơ đồ phòng'),
      bottomNavigationBar: const AdminBottomNavigation(
        selectedIndex: 2,
        popToParentOnReselect: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestore.watchProperties(),
        builder: (context, propertySnapshot) {
          if (!propertySnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final properties = propertySnapshot.data!;
          if (properties.isEmpty) {
            return const Center(child: Text('Chưa có cơ sở để hiển thị.'));
          }

          final selectedId = properties.any((item) => item['id'] == _propertyId)
              ? _propertyId!
              : properties.first['id'].toString();

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: firestore.watchRoomsByProperty(selectedId),
            builder: (context, roomSnapshot) {
              if (!roomSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final rooms = roomSnapshot.data!;
              final available = rooms.fold<int>(
                0,
                (total, room) => total + _asInt(room['availableCount']),
              );
              final paused = rooms
                  .where((room) => room['isOnSale'] == false)
                  .length;

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _PropertyPicker(
                        properties: properties,
                        selectedId: selectedId,
                        onChanged: (value) =>
                            setState(() => _propertyId = value),
                      ),
                      const SizedBox(height: 14),
                      _MapSummary(
                        roomTypes: rooms.length,
                        available: available,
                        paused: paused,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Khu vực nghỉ dưỡng',
                              style: TextStyle(
                                color: _ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '${rooms.length} hạng phòng',
                            style: const TextStyle(color: _muted, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      if (rooms.isEmpty)
                        const _EmptyPanel(
                          icon: Icons.bed_outlined,
                          title: 'Chưa có hạng phòng',
                          detail: 'Thêm hạng phòng trong mục Cấu hình.',
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                mainAxisExtent: 188,
                              ),
                          itemCount: rooms.length,
                          itemBuilder: (context, index) =>
                              _RoomMapTile(room: rooms[index]),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminCheckinScreen extends StatefulWidget {
  const AdminCheckinScreen({super.key});

  @override
  State<AdminCheckinScreen> createState() => _AdminCheckinScreenState();
}

class _AdminCheckinScreenState extends State<AdminCheckinScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final today = DateUtils.dateOnly(DateTime.now());
    final weekEnd = today.add(const Duration(days: 7));

    return Scaffold(
      backgroundColor: _canvas,
      appBar: const AdminHeader(title: 'Check-in & Cọc'),
      bottomNavigationBar: const AdminBottomNavigation(selectedIndex: 1),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestore.watchBookings(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!;
          final arrivals =
              bookings.where((booking) {
                final date = _readDate(booking['checkIn']);
                return date != null &&
                    !date.isBefore(today) &&
                    date.isBefore(weekEnd.add(const Duration(days: 1))) &&
                    booking['status']?.toString().toLowerCase() != 'cancelled';
              }).toList()..sort(
                (a, b) => (_readDate(a['checkIn']) ?? today).compareTo(
                  _readDate(b['checkIn']) ?? today,
                ),
              );
          final departures =
              bookings.where((booking) {
                final date = _readDate(booking['checkOut']);
                final status = booking['status']?.toString().toLowerCase();
                return date != null &&
                    !date.isBefore(today) &&
                    date.isBefore(weekEnd.add(const Duration(days: 1))) &&
                    status == 'checked_in';
              }).toList()..sort(
                (a, b) => (_readDate(a['checkOut']) ?? today).compareTo(
                  _readDate(b['checkOut']) ?? today,
                ),
              );
          final todayArrivals = arrivals.where((booking) {
            final date = _readDate(booking['checkIn']);
            return date != null && DateUtils.isSameDay(date, today);
          }).toList();
          final visibleArrivals = arrivals.where((booking) {
            if (_query.isEmpty) return true;
            final searchText = [
              booking['id'],
              booking['customerName'],
              booking['userName'],
              booking['guestName'],
            ].join(' ').toLowerCase();
            return searchText.contains(_query.toLowerCase());
          }).toList();
          final visibleDepartures = departures.where((booking) {
            if (_query.isEmpty) return true;
            final searchText = [
              booking['id'],
              booking['customerName'],
              booking['userName'],
              booking['guestName'],
            ].join(' ').toLowerCase();
            return searchText.contains(_query.toLowerCase());
          }).toList();
          final needsAttention = todayArrivals.where((booking) {
            final status = booking['status']?.toString().toLowerCase();
            return status != 'checked_in' &&
                status != 'checked_out' &&
                status != 'completed';
          }).length;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _CheckinOverview(
                    arrivals: todayArrivals.length,
                    attention: needsAttention,
                  ),
                  const SizedBox(height: 14),
                  const _QrEntryPanel(),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Khách đến trong 7 ngày',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${visibleArrivals.length} lượt',
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (value) => setState(() => _query = value.trim()),
                    decoration: InputDecoration(
                      hintText: 'Tìm mã vé hoặc tên khách',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (visibleArrivals.isEmpty && visibleDepartures.isEmpty)
                    _EmptyPanel(
                      icon: Icons.event_available_outlined,
                      title: _query.isEmpty
                          ? 'Chưa có khách sắp đến'
                          : 'Không tìm thấy booking',
                      detail: _query.isEmpty
                          ? 'Các booking mới sẽ xuất hiện tại đây.'
                          : 'Kiểm tra lại mã vé hoặc tên khách.',
                    )
                  else ...[
                    if (visibleArrivals.isNotEmpty) ...[
                      ...visibleArrivals.map(
                        (booking) =>
                            _ArrivalCard(booking: booking, today: today),
                      ),
                    ],
                    if (visibleDepartures.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Khách trả phòng trong 7 ngày',
                              style: TextStyle(
                                color: _ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '${visibleDepartures.length} lượt',
                            style: const TextStyle(color: _muted, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...visibleDepartures.map(
                        (booking) => _ArrivalCard(
                          booking: booking,
                          today: today,
                          isDeparture: true,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AdminOperationsDashboard extends StatefulWidget {
  const AdminOperationsDashboard({super.key});

  @override
  State<AdminOperationsDashboard> createState() =>
      _AdminOperationsDashboardState();
}

class _AdminOperationsDashboardState extends State<AdminOperationsDashboard> {
  RevenuePeriod _period = RevenuePeriod.month;
  late Future<RevenueReport> _reportFuture;

  @override
  void initState() {
    super.initState();
    _reportFuture = context.read<FirestoreService>().getRevenueReport(
      period: _period,
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    return FutureBuilder<RevenueReport>(
      future: _reportFuture,
      builder: (context, reportSnapshot) {
        if (reportSnapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Không thể tải báo cáo doanh thu: ${reportSnapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () => setState(
                      () => _reportFuture = firestore.getRevenueReport(
                        period: _period,
                      ),
                    ),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
        }
        if (!reportSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final report = reportSnapshot.data!;
        final propertyReports = report.properties;
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: firestore.watchUsers(),
          builder: (context, userSnapshot) {
            if (userSnapshot.hasError) {
              return Center(
                child: Text('Không thể tải nhân sự: ${userSnapshot.error}'),
              );
            }
            final users = userSnapshot.data ?? const <Map<String, dynamic>>[];
            final staffCount = users
                .where((user) => user['isStaff'] == true)
                .length;
            final ownerCount = users
                .where((user) => user['role']?.toString() == 'OWNER')
                .length;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
                  children: [
                    _OverviewMetricGrid(
                      metrics: [
                        _OverviewMetric(
                          title: 'Doanh thu tổng đã thu',
                          value:
                              '${NumberFormat.compact(locale: 'vi_VN').format(report.totalRevenue)} ₫',
                          icon: Icons.payments_outlined,
                        ),
                        _OverviewMetric(
                          title: 'Đơn đã thanh toán',
                          value: '${report.paidBookingCount}',
                          icon: Icons.verified_outlined,
                        ),
                        _OverviewMetric(
                          title: 'Khách sạn',
                          value: '${propertyReports.length}',
                          icon: Icons.apartment_outlined,
                        ),
                        _OverviewMetric(
                          title: 'Chủ khách sạn',
                          value: '$ownerCount',
                          icon: Icons.business_center_outlined,
                        ),
                        _OverviewMetric(
                          title: 'Nhân sự được phân công',
                          value: '$staffCount',
                          icon: Icons.groups_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    RevenuePeriodFilter(
                      value: _period,
                      onChanged: (period) => setState(() {
                        _period = period;
                        _reportFuture = firestore.getRevenueReport(
                          period: _period,
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    RevenueTrendChart(report: report),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: AdminSectionTitle(
                            title: 'Doanh thu theo khách sạn',
                            subtitle: 'Chỉ tổng hợp, không hiển thị thông tin đơn hàng',
                          ),
                        ),
                        IconButton(
                          tooltip: 'Làm mới doanh thu',
                          onPressed: () => setState(
                            () => _reportFuture = firestore.getRevenueReport(
                              period: _period,
                            ),
                          ),
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (propertyReports.isEmpty)
                      const AdminEmptyState(
                        icon: Icons.bar_chart_rounded,
                        title: 'Chưa có dữ liệu doanh thu',
                      )
                    else
                      _OverviewRevenueChart(
                        reports: propertyReports,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _OverviewRevenueChart extends StatelessWidget {
  const _OverviewRevenueChart({required this.reports});

  final List<RevenuePropertyReport> reports;

  @override
  Widget build(BuildContext context) {
    final rankedReports = reports
        .where((report) => report.revenue > 0)
        .take(6)
        .toList(growable: false);
    final maximumRevenue = rankedReports.fold<int>(
      0,
      (maximum, report) => maximum > report.revenue ? maximum : report.revenue,
    );
    final totalRevenue = reports.fold<int>(
      0,
      (total, report) => total + report.revenue,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: rankedReports.isEmpty
          ? const _RevenueChartEmptyState()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Doanh thu đã thanh toán',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Top ${rankedReports.length}',
                      style: const TextStyle(
                        color: _orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...rankedReports.asMap().entries.map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.key == rankedReports.length - 1 ? 0 : 14,
                    ),
                    child: _RevenueChartBar(
                      rank: entry.key + 1,
                      propertyName: entry.value.propertyName,
                      revenue: entry.value.revenue,
                      percentage: entry.value.revenue / maximumRevenue,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, color: Color(0xFFF0F1F5)),
                ),
                Row(
                  children: [
                    Text(
                      '${reports.length} khách sạn',
                      style: const TextStyle(color: _muted, fontSize: 10),
                    ),
                    const Spacer(),
                    Text(
                      'Tổng ${NumberFormat.compact(locale: 'vi_VN').format(totalRevenue)} ₫',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _RevenueChartBar extends StatelessWidget {
  const _RevenueChartBar({
    required this.rank,
    required this.propertyName,
    required this.revenue,
    required this.percentage,
  });

  final int rank;
  final String propertyName;
  final int revenue;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    final isLeader = rank == 1;
    final barColor = isLeader ? _orange : const Color(0xFF94A8CC);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 23,
          height: 23,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isLeader ? const Color(0xFFFFE7D3) : const Color(0xFFF1F4FA),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$rank',
            style: TextStyle(
              color: isLeader ? _orange : _muted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      propertyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${NumberFormat.compact(locale: 'vi_VN').format(revenue)} ₫',
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: SizedBox(
                  height: 8,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const ColoredBox(color: Color(0xFFF0F3F8)),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: percentage.clamp(0.0, 1.0).toDouble(),
                          child: ColoredBox(color: barColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RevenueChartEmptyState extends StatelessWidget {
  const _RevenueChartEmptyState();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 18),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.payments_outlined, color: _muted, size: 18),
        SizedBox(width: 8),
        Text(
          'Chưa có đơn đã thanh toán để lập biểu đồ.',
          style: TextStyle(color: _muted, fontSize: 11),
        ),
      ],
    ),
  );
}

class _OverviewMetric {
  const _OverviewMetric({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;
}

class _OverviewMetricGrid extends StatelessWidget {
  const _OverviewMetricGrid({required this.metrics});

  final List<_OverviewMetric> metrics;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var index = 0; index < metrics.length; index += 2) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 9));
      rows.add(
        Row(
          children: [
            Expanded(child: _OverviewMetricCard(metric: metrics[index])),
            const SizedBox(width: 9),
            Expanded(
              child: index + 1 < metrics.length
                  ? _OverviewMetricCard(metric: metrics[index + 1])
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }
    return Column(children: rows);
  }
}

class _OverviewMetricCard extends StatelessWidget {
  const _OverviewMetricCard({required this.metric});

  final _OverviewMetric metric;

  @override
  Widget build(BuildContext context) => Container(
    height: 105,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFFE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: _ink.withValues(alpha: 0.025),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 29,
          height: 29,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1E6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(metric.icon, color: _orange, size: 16),
        ),
        Text(
          metric.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          metric.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _muted, fontSize: 10),
        ),
      ],
    ),
  );
}

class _PropertyPicker extends StatelessWidget {
  const _PropertyPicker({
    required this.properties,
    required this.selectedId,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> properties;
  final String selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.apartment_rounded, color: _orange, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedId,
                isExpanded: true,
                items: properties
                    .map(
                      (property) => DropdownMenuItem<String>(
                        value: property['id'].toString(),
                        child: Text(
                          property['name']?.toString() ?? 'LuxeStay Resort',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onChanged(value);
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD9FFF1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '● LIVE',
              style: TextStyle(
                color: Color(0xFF087F5B),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapSummary extends StatelessWidget {
  const _MapSummary({
    required this.roomTypes,
    required this.available,
    required this.paused,
  });

  final int roomTypes;
  final int available;
  final int paused;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'TRẠNG THÁI VẬN HÀNH',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _CountBadge(label: '$available phòng còn'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$roomTypes hạng phòng',
            style: const TextStyle(
              color: _ink,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Expanded(
                  flex: available > 0 ? available : 1,
                  child: Container(height: 8, color: _ink),
                ),
                if (paused > 0) ...[
                  const SizedBox(width: 3),
                  Expanded(
                    flex: paused,
                    child: Container(height: 8, color: _orange),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _LegendDot(color: _green, label: 'Còn phòng ($available)'),
              const SizedBox(width: 14),
              _LegendDot(color: _orange, label: 'Ngừng bán ($paused)'),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomMapTile extends StatelessWidget {
  const _RoomMapTile({required this.room});

  final Map<String, dynamic> room;

  @override
  Widget build(BuildContext context) {
    final remaining = _asInt(room['availableCount']);
    final onSale = room['isOnSale'] != false;
    final image = room['image']?.toString() ?? '';
    final price = _asInt(room['pricePerNight'] ?? room['price']);
    final status = !onSale
        ? 'Ngừng bán'
        : remaining == 0
        ? 'Hết phòng'
        : 'Sẵn sàng';
    final statusColor = !onSale || remaining == 0
        ? const Color(0xFFFFE3D0)
        : const Color(0xFFD9FFF1);
    final statusText = !onSale || remaining == 0
        ? const Color(0xFFAA4B0A)
        : const Color(0xFF087F5B);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (image.isNotEmpty)
                  Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _roomImageFallback(),
                  )
                else
                  _roomImageFallback(),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusText,
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
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room['name']?.toString() ?? 'Hạng phòng',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$remaining phòng trống',
                        style: const TextStyle(color: _muted, fontSize: 10),
                      ),
                    ),
                    Text(
                      '${NumberFormat('#,###', 'vi_VN').format(price)}đ',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
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
}

class _CheckinOverview extends StatelessWidget {
  const _CheckinOverview({required this.arrivals, required this.attention});

  final int arrivals;
  final int attention;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NHẬN PHÒNG HÔM NAY',
            style: TextStyle(
              color: _muted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$arrivals lượt đến',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _CountBadge(label: '$attention cần xử lý', warning: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.label, this.warning = false});

  final String label;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: warning ? const Color(0xFFFFE1DB) : const Color(0xFFD9FFF1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: warning ? const Color(0xFFB42318) : const Color(0xFF087F5B),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _QrEntryPanel extends StatelessWidget {
  const _QrEntryPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF101725),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            height: 156,
            decoration: BoxDecoration(
              color: const Color(0xFF080D15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF313A49)),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner_rounded, color: _orange, size: 38),
                  SizedBox(height: 8),
                  Text(
                    'Camera QR chưa được kết nối',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Nhập mã đặt phòng để tìm khách',
                    style: TextStyle(color: Color(0xFF9AA5B5), fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrivalCard extends StatelessWidget {
  const _ArrivalCard({
    required this.booking,
    required this.today,
    this.isDeparture = false,
  });

  final Map<String, dynamic> booking;
  final DateTime today;
  final bool isDeparture;

  @override
  Widget build(BuildContext context) {
    final id = booking['id']?.toString() ?? '';
    final status = booking['status']?.toString().toLowerCase() ?? 'pending';
    final paid = booking['paymentStatus']?.toString().toLowerCase() == 'paid';
    final date = isDeparture
        ? _readDate(booking['checkOut'])
        : _readDate(booking['checkIn']);
    final isToday = date != null && DateUtils.isSameDay(date, today);
    final guest =
        booking['customerName']?.toString() ??
        booking['userName']?.toString() ??
        booking['guestName']?.toString() ??
        'Khách LuxeStay';
    final shortId = id.length > 8
        ? id.substring(0, 8).toUpperCase()
        : id.toUpperCase();
    final isCheckedIn = status == 'checked_in';
    final isCompleted = status == 'checked_out' || status == 'completed';
    final canCheckout = isDeparture && isCheckedIn && isToday;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 19,
                backgroundColor: _blue,
                child: Icon(
                  Icons.person_outline_rounded,
                  color: _ink,
                  size: 20,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guest,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Mã vé: #LUXE-$shortId',
                      style: const TextStyle(
                        color: Color(0xFF9A4B0B),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(status: status),
            ],
          ),
          const SizedBox(height: 11),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking['propertyName']?.toString() ?? 'LuxeStay Resort',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${booking['roomName'] ?? 'Hạng phòng'} • ${booking['guests'] ?? 1} khách',
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
                const SizedBox(height: 3),
                Text(
                  '${date == null ? 'Chưa rõ ngày' : DateFormat('dd/MM • HH:mm', 'vi').format(date)}  ·  ${paid ? 'Đã thanh toán' : 'Chưa thanh toán'}',
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: paid ? null : () => _updatePayment(context, id),
                  icon: Icon(
                    paid ? Icons.verified_rounded : Icons.payments_outlined,
                    size: 15,
                  ),
                  label: Text(
                    paid ? 'Đã thanh toán' : 'Xác nhận thanh toán',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    side: const BorderSide(color: Color(0xFFDDE3EF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isCompleted
                      ? null
                      : isDeparture
                      ? (canCheckout
                            ? () => _checkOut(context, id, status)
                            : null)
                      : (!isToday ||
                                status == 'checked_in' ||
                                status == 'completed'
                            ? null
                            : () => _checkIn(context, id, status)),
                  icon: Icon(
                    isCompleted
                        ? Icons.task_alt_rounded
                        : isDeparture
                        ? Icons.logout_rounded
                        : status == 'checked_in'
                        ? Icons.check_circle
                        : Icons.login_rounded,
                    size: 15,
                  ),
                  label: Text(
                    isCompleted
                        ? 'Đã trả phòng'
                        : isDeparture
                        ? (canCheckout
                              ? 'Xác nhận trả phòng'
                              : isCheckedIn
                              ? 'Đã nhận phòng'
                              : 'Trả phòng')
                        : status == 'checked_in'
                        ? 'Đã nhận phòng'
                        : !isToday
                        ? 'Chưa đến ngày'
                        : status == 'pending'
                        ? 'Xác nhận đơn'
                        : 'Nhận phòng',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _ink,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFDCFCEB),
                    disabledForegroundColor: const Color(0xFF087F5B),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updatePayment(BuildContext context, String id) async {
    await context.read<FirestoreService>().updatePaymentStatus(
      bookingId: id,
      paymentStatus: 'paid',
    );
  }

  Future<void> _checkIn(BuildContext context, String id, String status) async {
    final nextStatus = checkInStatusTransition(status);
    if (nextStatus == status) return;

    await context.read<FirestoreService>().updateBookingStatus(
      bookingId: id,
      status: nextStatus,
    );
  }

  Future<void> _checkOut(BuildContext context, String id, String status) async {
    final nextStatus = checkOutStatusTransition(status);
    if (nextStatus == status) return;

    await context.read<FirestoreService>().updateBookingStatus(
      bookingId: id,
      status: nextStatus,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final checkedIn = status == 'checked_in';
    final checkedOut = status == 'checked_out';
    final completed = status == 'completed';
    final confirmed = status == 'confirmed';
    final color = checkedIn || checkedOut || completed
        ? const Color(0xFFD9FFF1)
        : confirmed
        ? const Color(0xFFDDEAFF)
        : const Color(0xFFFFE1DB);
    final foreground = checkedIn || checkedOut || completed
        ? const Color(0xFF087F5B)
        : confirmed
        ? const Color(0xFF2055A5)
        : const Color(0xFFB42318);
    final label = checkedIn
        ? 'Đã nhận'
        : checkedOut
        ? 'Đã trả phòng'
        : completed
        ? 'Hoàn thành'
        : confirmed
        ? 'Đã xác nhận'
        : 'Chờ xử lý';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _muted, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(icon, color: _orange, size: 24),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _roomImageFallback() => Container(
  color: const Color(0xFFE8ECF5),
  child: const Center(
    child: Icon(Icons.king_bed_outlined, color: _muted, size: 30),
  ),
);

int _asInt(dynamic value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

DateTime? _readDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}
