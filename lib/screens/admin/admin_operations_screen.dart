import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/firestore_service.dart';
import '../../widgets/admin_chrome.dart';
import 'admin_rooms_screen.dart';

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
      bottomNavigationBar: AdminBottomNavigation(
        selectedIndex: 1,
        onSelected: (index) => _navigate(context, index, 1),
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
      bottomNavigationBar: AdminBottomNavigation(
        selectedIndex: 3,
        onSelected: (index) => _navigate(context, index, 3),
      ),
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
  const AdminOperationsDashboard({
    super.key,
    this.additionalContent = const [],
  });

  final List<Widget> additionalContent;

  @override
  State<AdminOperationsDashboard> createState() =>
      _AdminOperationsDashboardState();
}

class _AdminOperationsDashboardState extends State<AdminOperationsDashboard> {
  String _period = 'Hôm nay';

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();
    final today = DateUtils.dateOnly(DateTime.now());

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firestore.watchProperties(),
      builder: (context, propertySnapshot) =>
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: firestore.watchRooms(),
            builder: (context, roomSnapshot) =>
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: firestore.watchBookings(),
                  builder: (context, bookingSnapshot) {
                    final properties =
                        propertySnapshot.data ?? const <Map<String, dynamic>>[];
                    final rooms =
                        roomSnapshot.data ?? const <Map<String, dynamic>>[];
                    final bookings =
                        bookingSnapshot.data ?? const <Map<String, dynamic>>[];
                    final property = properties.isEmpty
                        ? const <String, dynamic>{}
                        : properties.first;
                    final arrivals = bookings
                        .where(
                          (booking) => _isSameDate(booking['checkIn'], today),
                        )
                        .toList();
                    final departures = bookings
                        .where(
                          (booking) => _isSameDate(booking['checkOut'], today),
                        )
                        .length;
                    final pending = bookings.where((booking) {
                      final status = booking['status']
                          ?.toString()
                          .toLowerCase();
                      return status == 'pending' || status == 'waiting';
                    }).toList();
                    final occupancyValues = properties
                        .map((item) => item['occupancyRate'])
                        .whereType<num>()
                        .map((value) => value.toDouble())
                        .toList();
                    final occupancy = occupancyValues.isEmpty
                        ? 0.0
                        : occupancyValues.reduce((a, b) => a + b) /
                              occupancyValues.length;
                    final periodRevenue = bookings
                        .where((booking) {
                          if (booking['paymentStatus']
                                  ?.toString()
                                  .toLowerCase() !=
                              'paid') {
                            return false;
                          }
                          final date =
                              _readDate(booking['createdAt']) ??
                              _readDate(booking['checkIn']);
                          return date != null &&
                              _isInPeriod(date, today, _period);
                        })
                        .fold<int>(
                          0,
                          (total, booking) =>
                              total + _asInt(booking['totalPrice']),
                        );
                    final weeklyArrivals = List<int>.generate(7, (index) {
                      final date = today.add(Duration(days: index));
                      return bookings
                          .where(
                            (booking) => _isSameDate(booking['checkIn'], date),
                          )
                          .length;
                    });

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
                          children: [
                            _PropertyHero(property: property),
                            const SizedBox(height: 10),
                            _PeriodSelector(
                              selected: _period,
                              onChanged: (period) =>
                                  setState(() => _period = period),
                            ),
                            const SizedBox(height: 12),
                            if (pending.isNotEmpty) ...[
                              _UrgentBookings(
                                count: pending.length,
                                bookings: pending.take(2).toList(),
                              ),
                              const SizedBox(height: 12),
                            ],
                            _RevenuePanel(
                              amount: periodRevenue,
                              period: _period,
                              unpaidCount: pending.length,
                            ),
                            const SizedBox(height: 14),
                            const _DashboardHeading(
                              title: 'Chỉ số vận hành ca',
                            ),
                            const SizedBox(height: 8),
                            _OccupancyPanel(
                              occupancy: occupancy,
                              propertyCount: properties.length,
                              roomCount: rooms.length,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _ArrivalDepartureTile(
                                    title: 'NHẬN PHÒNG',
                                    count: arrivals.length,
                                    icon: Icons.login_rounded,
                                    color: const Color(0xFFDBEAFE),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _ArrivalDepartureTile(
                                    title: 'TRẢ PHÒNG',
                                    count: departures,
                                    icon: Icons.logout_rounded,
                                    color: const Color(0xFFFFE7D6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _WeeklyArrivals(
                              values: weeklyArrivals,
                              today: today,
                            ),
                            if ((property['image']?.toString() ?? '')
                                .isNotEmpty) ...[
                              const SizedBox(height: 14),
                              _PropertyImageBanner(
                                image: property['image'].toString(),
                                name:
                                    property['name']?.toString() ??
                                    'LuxeStay Resort',
                                roomCount: rooms.length,
                              ),
                            ],
                            const SizedBox(height: 16),
                            const _DashboardHeading(title: 'Thao tác ca trực'),
                            const SizedBox(height: 8),
                            _QuickActions(
                              onSelected: (index) => _openTab(context, index),
                            ),
                            ...widget.additionalContent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
          ),
    );
  }
}

bool _isInPeriod(DateTime date, DateTime today, String period) {
  final day = DateUtils.dateOnly(date);
  if (period == 'Hôm nay') return DateUtils.isSameDay(day, today);
  if (period == 'Tuần này') {
    final start = today.subtract(Duration(days: today.weekday - 1));
    return !day.isBefore(start) &&
        day.isBefore(start.add(const Duration(days: 7)));
  }
  return day.year == today.year && day.month == today.month;
}

bool _isSameDate(dynamic value, DateTime date) {
  final parsed = _readDate(value);
  return parsed != null && DateUtils.isSameDay(parsed, date);
}

void _openTab(BuildContext context, int index) {
  final page = switch (index) {
    1 => const AdminRoomMapScreen(),
    2 => const AdminRoomsScreen(),
    _ => const AdminCheckinScreen(),
  };
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

class _PropertyHero extends StatelessWidget {
  const _PropertyHero({required this.property});

  final Map<String, dynamic> property;

  @override
  Widget build(BuildContext context) {
    final name = property['name']?.toString() ?? 'Cơ sở LuxeStay';
    final city =
        property['city']?.toString() ??
        property['location']?.toString() ??
        'Quản lý vận hành';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEFF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '✧ CƠ SỞ ĐANG VẬN HÀNH',
                  style: TextStyle(
                    color: Color(0xFF9A4B0B),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF70F1C5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  '● 24/7 Hoạt động',
                  style: TextStyle(
                    color: Color(0xFF075D47),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            city,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _muted, fontSize: 10),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ShiftInfo(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Ca làm việc hiện tại',
                  value: 'Ca sáng · 06:00 – 14:00',
                ),
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: _ShiftInfo(
                  icon: Icons.badge_outlined,
                  label: 'Quản lý trực ca',
                  value: 'Minh Tuấn',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShiftInfo extends StatelessWidget {
  const _ShiftInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF9A4B0B), size: 15),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 8),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const periods = ['Hôm nay', 'Tuần này', 'Tháng này'];
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _blue,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: periods.map((period) {
          final active = period == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? Colors.black : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period,
                  style: TextStyle(
                    color: active ? Colors.white : _ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _UrgentBookings extends StatelessWidget {
  const _UrgentBookings({required this.count, required this.bookings});

  final int count;
  final List<Map<String, dynamic>> bookings;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFDAD6),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFB42318),
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'CẦN XỬ LÝ KHẨN CẤP ($count)',
                style: const TextStyle(
                  color: Color(0xFF9B1C16),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Text(
              'Chờ xác nhận',
              style: TextStyle(color: Color(0xFF9B1C16), fontSize: 9),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...bookings.map(
          (booking) => Container(
            margin: const EdgeInsets.only(top: 5),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_note_outlined, color: _orange, size: 16),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '${booking['customerName'] ?? booking['userName'] ?? 'Khách mới'} · ${booking['propertyName'] ?? 'LuxeStay'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _RevenuePanel extends StatelessWidget {
  const _RevenuePanel({
    required this.amount,
    required this.period,
    required this.unpaidCount,
  });

  final int amount;
  final String period;
  final int unpaidCount;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFF131B2D),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF070C17)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.circle, color: _orange, size: 8),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'DOANH THU ĐÃ THANH TOÁN · $period'.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFFA7B0C0),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.trending_up_rounded, color: _green, size: 15),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          '${NumberFormat('#,###', 'vi_VN').format(amount)} ₫',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          '$unpaidCount booking chờ xác nhận',
          style: const TextStyle(color: Color(0xFFA7B0C0), fontSize: 9),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _RevenueSource(
              label: 'Đã thanh toán',
              value: NumberFormat.compact(locale: 'vi').format(amount),
            ),
            const SizedBox(width: 7),
            const _RevenueSource(label: 'Kênh', value: 'LuxeStay'),
            const SizedBox(width: 7),
            const _RevenueSource(label: 'Đối soát', value: 'Thủ công'),
          ],
        ),
      ],
    ),
  );
}

class _RevenueSource extends StatelessWidget {
  const _RevenueSource({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF293246),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFADB6C6), fontSize: 8),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

class _DashboardHeading extends StatelessWidget {
  const _DashboardHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: _ink,
      fontSize: 15,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _OccupancyPanel extends StatelessWidget {
  const _OccupancyPanel({
    required this.occupancy,
    required this.propertyCount,
    required this.roomCount,
  });

  final double occupancy;
  final int propertyCount;
  final int roomCount;

  @override
  Widget build(BuildContext context) {
    final progress = (occupancy / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tỷ lệ lấp đầy cơ sở',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${occupancy.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '$propertyCount cơ sở · $roomCount hạng phòng',
                  style: const TextStyle(color: _muted, fontSize: 9),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 62,
            height: 62,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  color: _orange,
                  backgroundColor: const Color(0xFFFFE4CE),
                ),
                Text(
                  '${occupancy.round()}%',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
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

class _ArrivalDepartureTile extends StatelessWidget {
  const _ArrivalDepartureTile({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String title;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(icon, size: 15, color: _ink),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '$count lượt',
          style: const TextStyle(
            color: _ink,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _WeeklyArrivals extends StatelessWidget {
  const _WeeklyArrivals({required this.values, required this.today});

  final List<int> values;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<int>(
      0,
      (current, value) => value > current ? value : current,
    );
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Xu hướng khách đến 7 ngày',
            style: TextStyle(
              color: _ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 76,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (index) {
                final value = values[index];
                final height = maxValue == 0 ? 8.0 : 10 + 48 * value / maxValue;
                final date = today.add(Duration(days: index));
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '$value',
                        style: const TextStyle(color: _muted, fontSize: 8),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        height: height,
                        width: 22,
                        decoration: BoxDecoration(
                          color: index == 0 ? _orange : const Color(0xFFD9E5FF),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('E', 'vi').format(date),
                        style: const TextStyle(color: _muted, fontSize: 8),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyImageBanner extends StatelessWidget {
  const _PropertyImageBanner({
    required this.image,
    required this.name,
    required this.roomCount,
  });

  final String image;
  final String name;
  final int roomCount;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(13),
    child: SizedBox(
      height: 116,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            image,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: _ink),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xCC111827)],
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 10,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tình trạng cơ sở',
                        style: TextStyle(color: Colors.white70, fontSize: 9),
                      ),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$roomCount hạng phòng',
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onSelected});

  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const actions = [
      (Icons.qr_code_scanner_rounded, 'Check-in & cọc', 3),
      (Icons.grid_view_rounded, 'Sơ đồ phòng', 1),
      (Icons.tune_rounded, 'Cấu hình phòng', 2),
      (Icons.receipt_long_outlined, 'Đơn đặt phòng', 3),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 54,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: () => onSelected(action.$3),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Icon(
                    action.$1,
                    color: index.isEven ? _orange : _ink,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      action.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

void _navigate(BuildContext context, int index, int selectedIndex) {
  if (index == selectedIndex) return;
  if (index == 0) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    return;
  }

  final page = switch (index) {
    1 => const AdminRoomMapScreen(),
    2 => const AdminRoomsScreen(),
    _ => const AdminCheckinScreen(),
  };
  Navigator.of(context)
      .pushReplacement(MaterialPageRoute<void>(builder: (_) => page));
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
