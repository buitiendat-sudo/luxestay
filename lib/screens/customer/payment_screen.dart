
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.bookingId,
  });

  final String bookingId;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const blue = Color(0xFF0876C9);
  static const orange = Color(0xFFFF641F);

  String method = 'vietqr';
  bool paying = false;
  bool saving = false;

  String money(int value) => NumberFormat.currency(
        locale: 'vi_VN',
        symbol: 'VND',
        decimalDigits: 0,
      ).format(value);

  String _normalizeMethod(String value) {
    switch (value) {
      case 'ewallet_qr':
        return 'wallet';
      case 'vietqr':
      case 'wallet':
      case 'mobile_banking':
      case 'credit_card':
      case 'pay_at_hotel':
        return value;
      default:
        return 'vietqr';
    }
  }

  Future<void> choose(
    Booking booking,
    FirestoreService db,
    String value,
  ) async {
    if (saving || booking.paymentStatus.toLowerCase() == 'paid') {
      return;
    }

    final previous = method;

    setState(() {
      method = value;
      saving = true;
    });

    try {
      await db.updateBooking(booking.id, {
        'paymentMethod': value == 'wallet' ? 'ewallet_qr' : value,
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => method = previous);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể lưu phương thức thanh toán: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> pay(
    Booking booking,
    FirestoreService db,
  ) async {
    if (paying || method == 'pay_at_hotel') return;

    setState(() => paying = true);

    try {
      // Chỉ mô phỏng thanh toán, không thu tiền thật.
      await db.updatePaymentStatus(
        bookingId: booking.id,
        paymentStatus: 'paid',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã ghi nhận thanh toán mô phỏng. Chưa thu tiền thật.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Thanh toán thất bại: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => paying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Vui lòng đăng nhập để thanh toán.'),
        ),
      );
    }

    final db = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: StreamBuilder<List<Booking>>(
          stream: db.getBookingsForUser(
            user.uid,
            userEmail: user.email,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: blue),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Không thể tải thông tin thanh toán:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }

            final bookings = (snapshot.data ?? <Booking>[])
                .where((b) => b.id == widget.bookingId)
                .toList();

            if (bookings.isEmpty) {
              return const Center(
                child: Text('Không tìm thấy thông tin booking.'),
              );
            }

            final booking = bookings.first;
            final paid =
                booking.paymentStatus.toLowerCase() == 'paid';

            final savedMethod =
                _normalizeMethod(booking.paymentMethod);

            if (method == 'vietqr' &&
                savedMethod != 'vietqr' &&
                !saving) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && method == 'vietqr') {
                  setState(() => method = savedMethod);
                }
              });
            }

            return Column(
              children: [
                _header(booking),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _paymentCard(booking, paid),
                      const SizedBox(height: 14),
                      _methods(booking, db, paid),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF5FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: blue,
                            ),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Đây là giao diện demo. QR chưa kết nối ngân hàng hoặc cổng thanh toán thật.',
                                style: TextStyle(
                                  color: Color(0xFF1B5C91),
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Cách thanh toán bằng QR',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Chọn VietQR trong phương thức thanh toán.\n'
                        '2. Với thanh toán thật, mở ứng dụng ngân hàng để quét mã.\n'
                        '3. Bản demo chưa tạo giao dịch hoặc thu tiền thật.',
                        style: TextStyle(
                          color: Color(0xFF697586),
                          height: 1.7,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                _bottomButton(booking, db, paid),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(Booking booking) {
    final dateFormat = DateFormat('dd/MM');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 18),
      decoration: const BoxDecoration(
        color: blue,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BID ${booking.id.toUpperCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      booking.propertyName.isEmpty
                          ? 'LuxeStay'
                          : booking.propertyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${dateFormat.format(booking.checkIn)} – '
                      '${dateFormat.format(booking.checkOut)} '
                      '(${booking.totalNights} đêm)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text(
                  'Chi tiết',
                  style: TextStyle(
                    color: blue,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Tổng giá tiền',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Center(
            child: Text(
              money(booking.totalPrice),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFF0565AD),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vui lòng hoàn tất thanh toán cho booking',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Icon(
                  Icons.verified_user_outlined,
                  color: Colors.white70,
                  size: 17,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentCard(Booking booking, bool paid) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5EAF0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Số tiền thanh toán',
                  style: TextStyle(
                    color: Color(0xFF697586),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  money(booking.totalPrice),
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 25),
          if (method == 'vietqr') ...[
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite,
                  color: Color(0xFFE53945),
                  size: 29,
                ),
                SizedBox(width: 4),
                Text(
                  'VietQR',
                  style: TextStyle(
                    color: Color(0xFF1D4265),
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'LUXESTAY DEMO PAYMENT',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 15),
            const _FakeQr(),
            const SizedBox(height: 12),
            const Text(
              'Mã QR minh họa — không thể quét để chuyển tiền thật.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
              ),
            ),
          ] else ...[
            Icon(
              method == 'wallet'
                  ? Icons.account_balance_wallet_outlined
                  : method == 'credit_card'
                      ? Icons.credit_card_outlined
                      : method == 'pay_at_hotel'
                          ? Icons.apartment_outlined
                          : Icons.phone_android,
              color: blue,
              size: 48,
            ),
            const SizedBox(height: 10),
            Text(
              method == 'wallet'
                  ? 'Ví điện tử · MoMo · ZaloPay'
                  : method == 'credit_card'
                      ? 'Thẻ tín dụng / ghi nợ'
                      : method == 'pay_at_hotel'
                          ? 'Thanh toán tại khách sạn'
                          : 'Ngân hàng di động',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Phương thức thanh toán minh họa',
              style: TextStyle(
                color: Color(0xFF697586),
                fontSize: 12,
              ),
            ),
          ],
          if (paid)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Đã ghi nhận thanh toán trong bản demo.',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _methods(
    Booking booking,
    FirestoreService db,
    bool paid,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5EAF0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _methodRow(
            booking, db, paid, 'vietqr',
            'VietQR', 'Thanh toán bằng mã QR ngân hàng',
            Icons.qr_code_2,
          ),
          const Divider(height: 1),
          _methodRow(
            booking, db, paid, 'wallet',
            'Digital Wallet',
            'Apple Pay · ZaloPay · MoMo · ShopeePay',
            Icons.account_balance_wallet_outlined,
          ),
          const Divider(height: 1),
          _methodRow(
            booking, db, paid, 'mobile_banking',
            'Ngân hàng di động',
            'Thanh toán qua ứng dụng ngân hàng',
            Icons.phone_android,
          ),
          const Divider(height: 1),
          _methodRow(
            booking, db, paid, 'credit_card',
            'Thẻ tín dụng / ghi nợ',
            'Visa · Mastercard · JCB',
            Icons.credit_card_outlined,
          ),
          const Divider(height: 1),
          _methodRow(
            booking, db, paid, 'pay_at_hotel',
            'Thanh toán tại khách sạn',
            'Thanh toán trực tiếp tại quầy lễ tân',
            Icons.apartment_outlined,
          ),
          if (saving)
            const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }

  Widget _methodRow(
    Booking booking,
    FirestoreService db,
    bool paid,
    String key,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final selected = method == key;

    return InkWell(
      onTap: paid || saving
          ? null
          : () => choose(booking, db, key),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected
                  ? blue
                  : const Color(0xFFB7C4D1),
              size: 22,
            ),
            const SizedBox(width: 10),
            Icon(
              icon,
              color: const Color(0xFF4E647A),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF182230),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF788596),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomButton(
    Booking booking,
    FirestoreService db,
    bool paid,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .08),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: paid ||
                        method == 'pay_at_hotel' ||
                        paying
                    ? null
                    : () => pay(booking, db),
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      const Color(0xFFCBD5E1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: paying
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : Text(
                        paid
                            ? 'ĐÃ GHI NHẬN THANH TOÁN'
                            : method == 'pay_at_hotel'
                                ? 'Thanh toán tại khách sạn'
                                : 'Thanh toán & hiển thị mã QR',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'LuxeStay · Thanh toán mô phỏng, chưa thu tiền thật',
              style: TextStyle(
                color: Color(0xFF8792A2),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FakeQr extends StatelessWidget {
  const _FakeQr();

  @override
  Widget build(BuildContext context) {
    const n = 25;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: SizedBox(
        width: 220,
        height: 220,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: n * n,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: n,
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
          ),
          itemBuilder: (context, i) {
            final r = i ~/ n;
            final c = i % n;

            bool finder(int top, int left) {
              final y = r - top;
              final x = c - left;

              if (y < 0 || y > 6 || x < 0 || x > 6) {
                return false;
              }

              return y == 0 ||
                  y == 6 ||
                  x == 0 ||
                  x == 6 ||
                  (y >= 2 && y <= 4 && x >= 2 && x <= 4);
            }

            final dark = finder(0, 0) ||
                finder(0, n - 7) ||
                finder(n - 7, 0) ||
                ((r * 17 + c * 11 + r * c) % 7 < 3);

            return ColoredBox(
              color: dark
                  ? const Color(0xFF101820)
                  : Colors.white,
            );
          },
        ),
      ),
    );
  }
}
