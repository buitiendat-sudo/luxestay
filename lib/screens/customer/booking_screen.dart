import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../models/property.dart';
import '../../models/room.dart';
import '../../services/firestore_service.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    required this.property,
    required this.room,
  });

  final Property property;
  final Room room;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  static const Color _navy = Color(0xFF0F172A);
  static const Color _gold = Color(0xFFD97706);
  static const Color _background = Color(0xFFF8F7F3);

  DateTime? _checkIn;
  DateTime? _checkOut;

  int _guests = 2;
  int _rooms = 1;

  bool _isLoading = false;

  int get _nights {
    if (_checkIn == null || _checkOut == null) {
      return 1;
    }

    final difference =
        _checkOut!.difference(_checkIn!).inDays;

    return difference > 0 ? difference : 1;
  }

  int get _totalPrice {
    return widget.room.pricePerNight *
        _nights *
        _rooms;
  }

  String _formatPrice(int price) {
    return NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    ).format(price);
  }

  Future<void> _selectDates() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(
        const Duration(days: 365),
      ),
      helpText: 'Chọn ngày nhận và trả phòng',
      cancelText: 'HỦY',
      confirmText: 'XÁC NHẬN',
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _checkIn = picked.start;
      _checkOut = picked.end;
    });
  }

  Future<void> _createBooking() async {
    if (_checkIn == null || _checkOut == null) {
      _showMessage(
        'Vui lòng chọn ngày nhận và trả phòng.',
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Vui lòng đăng nhập trước khi đặt phòng.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final booking = Booking(
        id: '',
        userId: user.uid,
        propertyId: widget.property.id,
        propertyName: widget.property.name,
        roomId: widget.room.id,
        roomName: widget.room.name,
        checkIn: _checkIn!,
        checkOut: _checkOut!,
        guests: _guests,
        rooms: _rooms,
        pricePerNight: widget.room.pricePerNight,
        totalNights: _nights,
        totalPrice: _totalPrice,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final firestoreService =
          context.read<FirestoreService>();

      final bookingId =
          await firestoreService.addBooking(
        booking.toFirestore(),
      );

      if (!mounted) {
        return;
      }

      await _showSuccessDialog(bookingId);
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Đặt phòng thất bại: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showSuccessDialog(
    String bookingId,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đặt phòng thành công',
                ),
              ),
            ],
          ),
          content: Text(
            'Mã đặt phòng của bạn:\n\n$bookingId',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Hoàn tất'),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Xác nhận đặt phòng',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: _background,
        foregroundColor: _navy,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          30,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _buildRoomCard(),

            const SizedBox(height: 20),

            _buildSectionTitle(
              'Thời gian lưu trú',
            ),

            const SizedBox(height: 10),

            _buildDateCard(),

            const SizedBox(height: 24),

            _buildSectionTitle(
              'Khách & phòng',
            ),

            const SizedBox(height: 10),

            _buildGuestCard(),

            const SizedBox(height: 24),

            _buildSectionTitle(
              'Chi tiết thanh toán',
            ),

            const SizedBox(height: 10),

            _buildPriceCard(),

            const SizedBox(height: 24),

            _buildNotice(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildRoomCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: Colors.black.withValues(alpha: 0.04),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: _navy,
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.hotel,
              color: _gold,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.property.name,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.room.name,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_formatPrice(widget.room.pricePerNight)} / đêm',
                  style: const TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: _navy,
        fontSize: 19,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildDateCard() {
    final dateFormat =
        DateFormat('dd/MM/yyyy');

    final checkInText = _checkIn == null
        ? 'Chọn ngày nhận phòng'
        : dateFormat.format(_checkIn!);

    final checkOutText = _checkOut == null
        ? 'Chọn ngày trả phòng'
        : dateFormat.format(_checkOut!);

    return InkWell(
      onTap: _selectDates,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: _dateItem(
                icon: Icons.login,
                title: 'Nhận phòng',
                value: checkInText,
              ),
            ),
            Container(
              width: 1,
              height: 50,
              color: Colors.grey.shade200,
            ),
            Expanded(
              child: _dateItem(
                icon: Icons.logout,
                title: 'Trả phòng',
                value: checkOutText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: _gold,
            size: 20,
          ),
          const SizedBox(height: 7),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: _navy,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _counterRow(
            title: 'Số khách',
            subtitle: 'Số người đi cùng',
            value: _guests,
            minValue: 1,
            onChanged: (value) {
              setState(() {
                _guests = value;
              });
            },
          ),
          const Divider(height: 25),
          _counterRow(
            title: 'Số phòng',
            subtitle: 'Số phòng muốn đặt',
            value: _rooms,
            minValue: 1,
            onChanged: (value) {
              setState(() {
                _rooms = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _counterRow({
    required String title,
    required String subtitle,
    required int value,
    required int minValue,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: value > minValue
              ? () => onChanged(value - 1)
              : null,
          icon: const Icon(
            Icons.remove_circle_outline,
          ),
        ),
        SizedBox(
          width: 25,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: () => onChanged(value + 1),
          icon: const Icon(
            Icons.add_circle_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _priceRow(
            'Giá phòng / đêm',
            _formatPrice(
              widget.room.pricePerNight,
            ),
          ),
          const SizedBox(height: 12),
          _priceRow(
            'Số đêm',
            '$_nights đêm',
          ),
          const SizedBox(height: 12),
          _priceRow(
            'Số phòng',
            '$_rooms phòng',
          ),
          const Padding(
            padding:
                EdgeInsets.symmetric(vertical: 15),
            child: Divider(),
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tổng cộng',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _formatPrice(_totalPrice),
                style: const TextStyle(
                  color: _gold,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    String title,
    String value,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _navy,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildNotice() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: _gold,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sau khi xác nhận, thông tin đặt phòng sẽ được lưu vào hệ thống LuxeStay.',
              style: TextStyle(
                color: _navy,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 15,
              offset: const Offset(0, -4),
              color: Colors.black.withValues(
                alpha: 0.08,
              ),
            ),
          ],
        ),
        child: SizedBox(
          height: 54,
          child: FilledButton(
            onPressed:
                _isLoading ? null : _createBooking,
            style: FilledButton.styleFrom(
              backgroundColor: _navy,
              disabledBackgroundColor:
                  Colors.grey.shade400,
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(15),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Xác nhận đặt phòng',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}