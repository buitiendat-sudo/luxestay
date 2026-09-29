import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({
    super.key,
    required this.bookingId,
  });

  final String bookingId;

  static const _navy = Color(0xFF0F172A);
  static const _background = Color(0xFFF8F9FF);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: _background,
        body: Center(child: Text('Vui lòng đăng nhập để xem thanh toán.')),
      );
    }

    final bookingsStream = context.read<FirestoreService>().getBookingsForUser(
          user.uid,
          userEmail: user.email,
        );
    final firestore = context.read<FirestoreService>();
    final customerName = user.displayName?.trim().isNotEmpty == true
      ? user.displayName!.trim()
      : 'Khách hàng LuxeStay';

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Thanh toán'),
        backgroundColor: _background,
      ),
      body: SafeArea(
        child: StreamBuilder<List<Booking>>(
          stream: bookingsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _navy),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Không thể tải thông tin thanh toán.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

                    final bookings = (snapshot.data ?? const <Booking>[])
                        .where((booking) => booking.id == bookingId)
                        .toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chi tiết thanh toán',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Kiểm tra thông tin booking trước khi thanh toán.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
                if (bookings.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Không tìm thấy thông tin booking này.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.builder(
                      itemCount: 1,
                      itemBuilder: (context, index) => _PaymentBookingTile(
                        booking: bookings.single,
                        firestore: firestore,
                        customerName: customerName,
                        customerEmail: user.email ?? 'Chưa cập nhật email',
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

}

class _PaymentBookingTile extends StatefulWidget {
  const _PaymentBookingTile({
    required this.booking,
    required this.firestore,
    required this.customerName,
    required this.customerEmail,
  });

  final Booking booking;
  final FirestoreService firestore;
  final String customerName;
  final String customerEmail;

  @override
  State<_PaymentBookingTile> createState() => _PaymentBookingTileState();
}

class _PaymentBookingTileState extends State<_PaymentBookingTile> {
  late String _paymentMethod;
  bool _isSaving = false;
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    _paymentMethod = widget.booking.paymentMethod;
  }

  @override
  void didUpdateWidget(covariant _PaymentBookingTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.booking.paymentMethod != widget.booking.paymentMethod) {
      _paymentMethod = widget.booking.paymentMethod;
    }
  }

  Future<void> _selectPaymentMethod(String method) async {
    if (_isSaving || widget.booking.paymentStatus == 'paid') return;

    final previousMethod = _paymentMethod;
    setState(() {
      _paymentMethod = method;
      _isSaving = true;
    });

    try {
      await widget.firestore.updateBooking(
        widget.booking.id,
        {'paymentMethod': method},
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _paymentMethod = previousMethod);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu phương thức: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _simulatePayment() async {
    if (_isPaying || _paymentMethod == 'pay_at_hotel') return;

    setState(() => _isPaying = true);
    try {
      await widget.firestore.updatePaymentStatus(
        bookingId: widget.booking.id,
        paymentStatus: 'paid',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã ghi nhận thanh toán mô phỏng.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thanh toán thất bại: $error')),
      );
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final paid = booking.paymentStatus.toLowerCase() == 'paid';
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _StayIcon(),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.propertyName.isEmpty
                          ? 'LuxeStay'
                          : booking.propertyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      booking.roomName.isEmpty ? 'Đặt phòng' : booking.roomName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '${booking.guests} khách · ${booking.rooms} phòng',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              _PaymentStatusBadge(paid: paid),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _DateColumn(
                    label: 'Nhận phòng',
                    date: dateFormat.format(booking.checkIn),
                  ),
                ),
                Text(
                  '${booking.totalNights} đêm',
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Expanded(
                  child: _DateColumn(
                    label: 'Trả phòng',
                    date: dateFormat.format(booking.checkOut),
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionTitle(
            title: 'Thông tin khách hàng',
            trailing: '#${booking.id.length > 8 ? booking.id.substring(0, 8).toUpperCase() : booking.id.toUpperCase()}',
          ),
          const SizedBox(height: 7),
          _InfoLine(icon: Icons.person_outline, label: widget.customerName),
          _InfoLine(icon: Icons.email_outlined, label: widget.customerEmail),
          const SizedBox(height: 14),
          const _SectionTitle(title: 'Chi tiết giá'),
          const SizedBox(height: 7),
          _PriceLine(
            label: 'Giá phòng × ${booking.totalNights} đêm × ${booking.rooms} phòng',
            value: _money(booking.pricePerNight * booking.totalNights * booking.rooms),
          ),
          const Divider(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tổng thanh toán',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _money(booking.totalPrice),
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: _SectionTitle(title: 'Phương thức thanh toán'),
              ),
              const _SimulationBadge(),
            ],
          ),
          const SizedBox(height: 8),
          _PaymentMethodOption(
            selected: _paymentMethod == 'credit_card',
            enabled: !paid && !_isSaving,
            icon: Icons.credit_card_outlined,
            title: 'Thẻ tín dụng / Ghi nợ quốc tế',
            subtitle: 'Hỗ trợ Visa, Mastercard, JCB',
            badge: 'VISA / MC',
            onTap: () => _selectPaymentMethod('credit_card'),
          ),
          if (_paymentMethod == 'credit_card') ...[
            const SizedBox(height: 8),
            const _MockCard(),
          ],
          const SizedBox(height: 5),
          _PaymentMethodOption(
            selected: _paymentMethod == 'ewallet_qr',
            enabled: !paid && !_isSaving,
            icon: Icons.qr_code_2,
            title: 'Ví điện tử / QR',
            subtitle: 'MoMo, ZaloPay, VNPay QR',
            onTap: () => _selectPaymentMethod('ewallet_qr'),
          ),
          if (_paymentMethod == 'ewallet_qr')
            const _MethodNote('Mã QR sẽ được cung cấp khi kết nối cổng thanh toán.'),
          const SizedBox(height: 5),
          _PaymentMethodOption(
            selected: _paymentMethod == 'pay_at_hotel',
            enabled: !paid && !_isSaving,
            icon: Icons.apartment_outlined,
            title: 'Thanh toán khi nhận phòng',
            subtitle: 'Thanh toán trực tiếp tại quầy lễ tân',
            onTap: () => _selectPaymentMethod('pay_at_hotel'),
          ),
          if (_paymentMethod == 'pay_at_hotel')
            const _MethodNote('Bạn sẽ thanh toán trực tiếp tại khách sạn.'),
          const SizedBox(height: 12),
          if (paid)
            const _MethodNote('Khoản thanh toán này đã được ghi nhận.', success: true)
          else if (_paymentMethod != 'pay_at_hotel')
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: _isPaying ? null : _simulatePayment,
                icon: _isPaying
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_outline, size: 18),
                label: Text(_isPaying ? 'Đang xử lý' : 'Thanh toán mô phỏng'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          const SizedBox(height: 8),
          const _MethodNote(
            'Giao dịch hiện ở chế độ mô phỏng, chưa thu tiền thật.',
          ),
        ],
      ),
    );
  }

  String _money(int value) => NumberFormat.currency(
        locale: 'vi_VN',
        symbol: '₫',
        decimalDigits: 0,
      ).format(value);
}

class _StayIcon extends StatelessWidget {
  const _StayIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.hotel_outlined,
        color: Color(0xFF0F172A),
        size: 28,
      ),
    );
  }
}

class _DateColumn extends StatelessWidget {
  const _DateColumn({
    required this.label,
    required this.date,
    this.alignEnd = false,
  });

  final String label;
  final String date;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          date,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 9,
            ),
          ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SimulationBadge extends StatelessWidget {
  const _SimulationBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE9D5),
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Text(
        'MÔ PHỎNG',
        style: TextStyle(
          color: Color(0xFF7C2D12),
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  const _PaymentMethodOption({
    required this.selected,
    required this.enabled,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  final bool selected;
  final bool enabled;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEAF1FF) : Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1),
                size: 20,
              ),
              const SizedBox(width: 9),
              Icon(icon, color: const Color(0xFF64748B), size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE9D5),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Color(0xFF7C2D12),
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MockCard extends StatelessWidget {
  const _MockCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 34),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(9),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thẻ mô phỏng',
            style: TextStyle(fontSize: 9, color: Color(0xFF64748B)),
          ),
          SizedBox(height: 6),
          Text(
            '••••  ••••  ••••  4242',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Không nhập thông tin thẻ thật vào bản mô phỏng.',
            style: TextStyle(fontSize: 9, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _MethodNote extends StatelessWidget {
  const _MethodNote(this.message, {this.success = false});

  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final color = success ? const Color(0xFF047857) : const Color(0xFF64748B);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 7),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: success ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            success ? Icons.check_circle_outline : Icons.info_outline,
            color: color,
            size: 15,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 9, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  const _PaymentStatusBadge({required this.paid});

  final bool paid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: paid ? const Color(0xFFDCFCE7) : const Color(0xFFFFEDD5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        paid ? 'Đã thanh toán' : 'Chưa thanh toán',
        style: TextStyle(
          color: paid ? const Color(0xFF15803D) : const Color(0xFF9A3412),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}