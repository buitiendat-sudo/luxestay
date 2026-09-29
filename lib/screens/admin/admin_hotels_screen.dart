import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../services/firestore_service.dart';
import '../../services/google_geocoding_service.dart';
import '../../widgets/admin_chrome.dart';
import 'admin_bookings_screen.dart';
import 'admin_rooms_screen.dart';
import 'admin_users_screen.dart';

class AdminHotelsScreen extends StatelessWidget {
  const AdminHotelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: const AdminHeader(title: 'Quản lý Khách sạn'),
      bottomNavigationBar: AdminBottomNavigation(
        selectedIndex: 0,
        onSelected: (index) {
          if (index == 0) return;

          final page = switch (index) {
            1 => const AdminRoomsScreen(),
            2 => const AdminBookingsScreen(),
            _ => const AdminUsersScreen(),
          };

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestore.watchProperties(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final hotels = snapshot.data!;

          final averageRating = _averageRating(hotels);

          final revenue = hotels.fold<int>(
            0,
            (total, hotel) => total + _toInt(hotel['monthlyRevenue']),
          );

          final occupancy = _averageOccupancy(hotels);

          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              const Text(
                'Tổng quan hệ thống',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
              ),

              const SizedBox(height: 4),

              const Text(
                'Theo dõi các cơ sở LuxeStay trong thời gian thực.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),

              const SizedBox(height: 14),

              _GeocodePropertiesButton(hotels: hotels),

              const SizedBox(height: 18),

              SizedBox(
                height: 122,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    SizedBox(
                      width: 145,
                      child: AdminKpiCard(
                        title: 'Cơ sở trực thuộc',
                        value: '${hotels.length}',
                        icon: Icons.apartment_outlined,
                      ),
                    ),
                    const SizedBox(width: 9),
                    SizedBox(
                      width: 145,
                      child: AdminKpiCard(
                        title: 'Tỷ lệ lấp đầy',
                        value: '${occupancy.toStringAsFixed(1)}%',
                        icon: Icons.donut_large_outlined,
                      ),
                    ),
                    const SizedBox(width: 9),
                    SizedBox(
                      width: 145,
                      child: AdminKpiCard(
                        title: 'Đánh giá',
                        value: '${averageRating.toStringAsFixed(2)}/5',
                        icon: Icons.star_outline,
                      ),
                    ),
                    const SizedBox(width: 9),
                    SizedBox(
                      width: 170,
                      child: AdminKpiCard(
                        title: 'Doanh thu tháng',
                        value: _money(revenue),
                        icon: Icons.payments_outlined,
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
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    '${hotels.length} cơ sở',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              if (hotels.isEmpty)
                const _EmptyHotel()
              else
                ...hotels.map((hotel) => _HotelCard(hotel: hotel)),
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
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _averageRating(List<Map<String, dynamic>> hotels) {
    if (hotels.isEmpty) return 0;

    var total = 0.0;

    for (final hotel in hotels) {
      total += (hotel['rating'] as num?)?.toDouble() ?? 0;
    }

    return total / hotels.length;
  }

  static double _averageOccupancy(List<Map<String, dynamic>> hotels) {
    if (hotels.isEmpty) return 0;

    var total = 0.0;

    for (final hotel in hotels) {
      total += (hotel['occupancyRate'] as num?)?.toDouble() ?? 0;
    }

    return total / hotels.length;
  }

  static String _money(int value) {
    return '${NumberFormat('#,###', 'vi_VN').format(value)} ₫';
  }
}

class _HotelCard extends StatelessWidget {
  const _HotelCard({required this.hotel});

  final Map<String, dynamic> hotel;

  @override
  Widget build(BuildContext context) {
    final firestore = context.read<FirestoreService>();

    final id = hotel['id']?.toString() ?? '';

    final image = hotel['image']?.toString() ?? '';

    final active = hotel['isActive'] != false;

    final rating = (hotel['rating'] as num?)?.toDouble() ?? 0;

    final occupancy = (hotel['occupancyRate'] as num?)?.toDouble() ?? 0;
    final latitude = hotel['latitude'];
    final longitude = hotel['longitude'];
    final hasCoordinates = latitude is num && longitude is num;
    final locationType = hotel['geocodingLocationType']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
                    errorBuilder: (_, _, _) => _fallback(),
                  )
                else
                  _fallback(),

                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xAA000000)],
                    ),
                  ),
                ),

                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      active ? 'Đang hoạt động' : 'Tạm dừng',
                      style: TextStyle(
                        color: active
                            ? const Color(0xFF15803D)
                            : const Color(0xFFDC2626),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 11,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hotel['name']?.toString() ?? 'LuxeStay Resort',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hotel['location']?.toString() ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
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
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _HotelMetric(
                        label: 'Công suất',
                        value: '${occupancy.toStringAsFixed(1)}%',
                      ),
                    ),
                    Expanded(
                      child: _HotelMetric(
                        label: 'Phân hạng',
                        value: '${rating.toStringAsFixed(1)} ★',
                      ),
                    ),
                    Expanded(
                      child: _HotelMetric(
                        label: 'Giá từ',
                        value: _shortPrice(hotel['pricePerNight']),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        hasCoordinates
                            ? '${latitude.toStringAsFixed(6)}, '
                                  '${longitude.toStringAsFixed(6)}'
                                  '${locationType.isEmpty ? '' : ' · $locationType'}'
                            : 'Chưa có tọa độ',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 11),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mở màn điều phối phòng.'),
                            ),
                          );
                        },
                        child: const Text('Điều phối'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text('Sửa'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: FilledButton(
                        onPressed: id.isEmpty
                            ? null
                            : () {
                                firestore.setPropertyActiveStatus(id, !active);
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: active
                              ? const Color(0xFF111827)
                              : const Color(0xFF059669),
                        ),
                        child: Text(
                          active ? 'Tạm dừng' : 'Mở lại',
                          style: const TextStyle(fontSize: 10),
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
      color: const Color(0xFFE2E8F0),
      child: const Icon(Icons.apartment, size: 50),
    );
  }

  static String _shortPrice(dynamic value) {
    final number = (value as num?)?.toInt() ?? 0;

    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}tr';
    }

    return NumberFormat.compact(locale: 'vi').format(number);
  }
}

class _GeocodePropertiesButton extends StatefulWidget {
  const _GeocodePropertiesButton({required this.hotels});

  final List<Map<String, dynamic>> hotels;

  @override
  State<_GeocodePropertiesButton> createState() =>
      _GeocodePropertiesButtonState();
}

class _GeocodePropertiesButtonState extends State<_GeocodePropertiesButton> {
  final GoogleGeocodingService _geocodingService = GoogleGeocodingService();
  bool _isRunning = false;
  int _completed = 0;
  int _total = 0;

  @override
  void dispose() {
    _geocodingService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isRunning ? null : _geocodeMissingProperties,
        icon: _isRunning
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.add_location_alt_outlined),
        label: Text(
          _isRunning
              ? 'Đang lấy tọa độ ($_completed/$_total)'
              : 'Lấy tọa độ resort chưa có',
        ),
      ),
    );
  }

  Future<void> _geocodeMissingProperties() async {
    if (!_geocodingService.isConfigured) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cần cấu hình Google Maps API'),
          content: const Text(
            'Bật Geocoding API trong Google Cloud và chạy ứng dụng với '
            '--dart-define=GOOGLE_MAPS_API_KEY=YOUR_API_KEY. '
            'Hãy giới hạn API key theo ứng dụng và chỉ bật Geocoding API.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      return;
    }

    final firestore = context.read<FirestoreService>();
    final pending = widget.hotels
        .where((hotel) => !_hasCoordinates(hotel))
        .toList(growable: false);
    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tất cả resort đã có tọa độ.')),
      );
      return;
    }

    setState(() {
      _isRunning = true;
      _completed = 0;
      _total = pending.length;
    });

    var updated = 0;
    final failures = <String>[];

    try {
      for (var index = 0; index < pending.length; index++) {
        if (!mounted) return;
        setState(() => _completed = index + 1);

        final hotel = pending[index];
        final name = hotel['name']?.toString().trim() ?? '';
        final id = hotel['id']?.toString() ?? '';

        try {
          if (id.isEmpty) {
            throw const GoogleGeocodingException(
              'Không tìm thấy mã resort trong Firestore.',
            );
          }

          final coordinates = await _geocodingService.geocodeHotel(
            name: name,
            location: hotel['location']?.toString() ?? '',
            address: hotel['address']?.toString(),
          );
          await firestore.updatePropertyCoordinates(
            propertyId: id,
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
            formattedAddress: coordinates.formattedAddress,
            locationType: coordinates.locationType,
          );
          updated++;
        } on GoogleGeocodingException catch (error) {
          failures.add('$name: ${error.message}');
        } on http.ClientException catch (error) {
          failures.add('$name: Lỗi kết nối tới Google (${error.message}).');
        } on FirebaseException catch (error) {
          failures.add(
            '$name: Không lưu được tọa độ vào Firestore '
            '(${error.message ?? error.code}).',
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isRunning = false);
      }
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hoàn tất lấy tọa độ'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Đã cập nhật $updated/${pending.length} resort.'),
              if (failures.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Không xử lý được ${failures.length} resort:',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    itemCount: failures.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        failures[index],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  bool _hasCoordinates(Map<String, dynamic> hotel) {
    final latitude = hotel['latitude'];
    final longitude = hotel['longitude'];
    return latitude is num &&
        longitude is num &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }
}

class _HotelMetric extends StatelessWidget {
  const _HotelMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyHotel extends StatelessWidget {
  const _EmptyHotel();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(child: Text('Chưa có cơ sở.')),
    );
  }
}
