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
  static const Color _background = Color(0xFFF8F9FF);

  DateTime? _checkIn;
  DateTime? _checkOut;

  int _guests = 2;
  int _rooms = 1;

  bool _isLoading = false;

  int get _nights {
    if (_checkIn == null || _checkOut == null) {
      return 1;
    }

    final difference = _checkOut!.difference(_checkIn!).inDays;

    return difference > 0 ? difference : 1;
  }

  int get _totalPrice {
    return widget.room.pricePerNight * _nights * _rooms;
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

    if (!mounted || picked == null) {
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

    final firestoreService = context.read<FirestoreService>();

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

      final bookingId = await firestoreService.addBooking(
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
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Color(0xFF10B981),
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
                Navigator.pop(dialogContext);

                if (mounted) {
                  Navigator.pop(context);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: _navy,
              ),
              child: const Text(
                'Hoàn tất',
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

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
        actions: [
          IconButton(
            tooltip: 'Chia sẻ',
            onPressed: () {},
            icon: const Icon(
              Icons.share_outlined,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 14),
            child: CircleAvatar(
              radius: 15,
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          30,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgress(),
            const SizedBox(height: 14),
            _buildProtection(),
            const SizedBox(height: 14),
            _buildRoomCard(),
            const SizedBox(height: 14),
            _buildGuestCard(),
            const SizedBox(height: 20),
            _buildCustomerInfo(),
            const SizedBox(height: 24),
            _buildSectionTitle(
              'Chi tiết thanh toán',
            ),
            const SizedBox(height: 10),
            _buildPriceCard(),
            const SizedBox(height: 24),
            _buildPaymentOptions(),
            const SizedBox(height: 18),
            _buildNotice(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 11,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: Colors.black,
            child: Icon(
              Icons.check,
              size: 14,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 7),
          Text(
            '1. Chọn phòng',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Divider(
              indent: 10,
              endIndent: 10,
            ),
          ),
          CircleAvatar(
            radius: 11,
            backgroundColor: _navy,
            child: Text(
              '2',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 7),
          Text(
            'Thanh toán & Xác nhận',
            style: TextStyle(
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: Color(0xFF6FFBBE),
            child: Icon(
              Icons.verified_user_outlined,
              color: Color(0xFF006D4A),
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bảo đảm giá tốt nhất & Phòng có sẵn',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                Text(
                  'Hỗ trợ đội ngũ quản gia trực tuyến 24/7',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard() {
    final image = widget.room.image.isNotEmpty
        ? widget.room.image
        : widget.property.image;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'THÔNG TIN KỲ NGHỈ',
                style: TextStyle(
                  color: _gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Spacer(),
              _BookingTag('☆ 5 sao Luxury'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: image.isEmpty
                      ? const ColoredBox(
                          color: Color(0xFFE2E8F0),
                        )
                      : Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (
                            context,
                            error,
                            stackTrace,
                          ) {
                            return const ColoredBox(
                              color: Color(0xFFE2E8F0),
                              child: Icon(
                                Icons.hotel,
                                color: Color(0xFF94A3B8),
                              ),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.property.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.room.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$_guests khách · $_rooms phòng',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildDateCard(),
          const SizedBox(height: 10),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Color(0xFF10B981),
                size: 15,
              ),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Chính sách hủy phòng được áp dụng theo điều kiện của LuxeStay.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF047857),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard() {
    final dateFormat = DateFormat(
      'dd/MM/yyyy',
    );

    final checkInText = _checkIn == null
        ? 'Chọn ngày'
        : dateFormat.format(_checkIn!);

    final checkOutText = _checkOut == null
        ? 'Chọn ngày'
        : dateFormat.format(_checkOut!);

    return InkWell(
      onTap: _selectDates,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
          ),
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
              height: 45,
              color: const Color(0xFFE2E8F0),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: _gold,
            size: 18,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: _navy,
              fontSize: 12,
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                style: const TextStyle(
                  color: Color(0xFF64748B),
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
          onPressed: () {
            onChanged(value + 1);
          },
          icon: const Icon(
            Icons.add_circle_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfo() {
    final user = FirebaseAuth.instance.currentUser;

    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : 'Khách hàng LuxeStay';

    final email = user?.email ?? 'Chưa cập nhật email';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Thông tin khách hàng',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _BookingTag('Tài khoản'),
            ],
          ),
          const SizedBox(height: 13),
          _customerCell(
            Icons.person_outline,
            'Họ và tên khách',
            name,
          ),
          const SizedBox(height: 6),
          _customerCell(
            Icons.email_outlined,
            'Email',
            email,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yêu cầu đặc biệt',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 7),
                Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    _BookingTag('Phòng tầng cao'),
                    _BookingTag('King Bed'),
                    _BookingTag('Check-in sớm'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerCell(
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: const Color(0xFF475569),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
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
            padding: EdgeInsets.symmetric(
              vertical: 15,
            ),
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
            style: const TextStyle(
              color: Color(0xFF64748B),
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

  Widget _buildPaymentOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Phương thức thanh toán',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _BookingTag('MÔ PHỎNG'),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.radio_button_checked,
                      color: Colors.black,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Thẻ tín dụng / Ghi nợ quốc tế',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _BookingTag('VISA / MC'),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: 34,
                    top: 3,
                  ),
                  child: Text(
                    'Hỗ trợ Visa, Mastercard, JCB',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                _CardPreview(),
              ],
            ),
          ),
          const SizedBox(height: 13),
          _paymentRow(
            Icons.radio_button_off,
            'Ví điện tử / QR',
            'MoMo, ZaloPay, VNPay QR',
          ),
          const SizedBox(height: 12),
          _paymentRow(
            Icons.radio_button_off,
            'Thanh toán khi nhận phòng',
            'Thanh toán trực tiếp tại quầy lễ tân',
          ),
        ],
      ),
    );
  }

  Widget _paymentRow(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFFC8DDFC),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.qr_code_2,
          size: 16,
          color: Color(0xFF64748B),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TỔNG THANH TOÁN',
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    _formatPrice(_totalPrice),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed:
                    _isLoading ? null : _createBooking,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  disabledBackgroundColor:
                      Colors.grey.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
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
                        'Xác nhận & Thanh toán',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingTag extends StatelessWidget {
  const _BookingTag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8D7),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF663500),
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CardPreview extends StatelessWidget {
  const _CardPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thẻ mô phỏng',
            style: TextStyle(
              fontSize: 9,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '••••  ••••  ••••  4242',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 7),
          Row(
            children: [
              Text(
                'Hết hạn: 08/28',
                style: TextStyle(
                  fontSize: 9,
                ),
              ),
              Spacer(),
              Text(
                'CVV: •••',
                style: TextStyle(
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}