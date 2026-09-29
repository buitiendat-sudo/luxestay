import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'register_screen.dart';

const _navy = Color(0xFF0F172A);
const _gold = Color(0xFFD97706);
const _background = Color(0xFFF8F9FF);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng nhập thành công!'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Đăng nhập thất bại.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) => Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _topBar(),
                    const SizedBox(height: 12),
                    _hero(),
                    const SizedBox(height: 24),
                    _memberOffer(),
                    const SizedBox(height: 22),
                    _tabs(),
                    const SizedBox(height: 22),
                    _loginPanel(authProvider),
                    const SizedBox(height: 22),
                    _registerOffer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() => Row(children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.home_outlined, color: _gold, size: 21)),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('LuxeStay', style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: _navy)), Text('Tài khoản', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF64748B)))])),
        const Icon(Icons.notifications_none_rounded, color: _navy),
        const SizedBox(width: 16),
        const CircleAvatar(radius: 17, backgroundImage: NetworkImage('https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100')),
      ]);

  Widget _hero() => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(height: 175, child: Stack(fit: StackFit.expand, children: [
          Image.network('https://images.unsplash.com/photo-1540541338287-41700207dee6?w=900', fit: BoxFit.cover),
          DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, _navy.withValues(alpha: .88)]))),
          const Positioned(left: 16, right: 16, bottom: 15, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('✦ LUXESTAY PRIVÉ CLUB', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)), SizedBox(height: 5), Text('Trải nghiệm nghỉ dưỡng đẳng cấp', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800, height: 1.18)), SizedBox(height: 5), Text('Chào mừng đến với LuxeStay. Khám phá hạng nghỉ thứ sang trọng.', style: TextStyle(color: Color(0xFFD8DEE8), fontSize: 11, height: 1.45))]) )
        ])),
      );

  Widget _memberOffer() => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFE7F0FF), borderRadius: BorderRadius.circular(14)), child: const Row(children: [CircleAvatar(backgroundColor: Color(0xFFF9E5D5), child: Icon(Icons.workspace_premium_outlined, color: _gold, size: 20)), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Đặc quyền thành viên mới  -10%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _navy)), SizedBox(height: 3), Text('Giảm ngay 10% cho lần đặt phòng đầu tiên và tích lũy điểm thưởng LuxeClub trọn đời.', style: TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.4))]))]));

  Widget _tabs() => Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE4EEFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x160F172A),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: const Text(
                  'Đăng nhập',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _openRegister,
                  child: const Center(
                    child: Text(
                      'Đăng ký',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  void _openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }

  Widget _loginPanel(AuthProvider authProvider) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: _navy.withValues(alpha: .08), blurRadius: 16, offset: const Offset(0, 5))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _field(controller: _emailController, label: 'Số điện thoại hoặc Email *', hint: 'vd: traveler@luxestay.vn', icon: Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress, validator: (value) => value == null || !value.contains('@') ? 'Nhập email hợp lệ' : null),
          const SizedBox(height: 16),
          _field(controller: _passwordController, label: 'Mật khẩu *', hint: 'Tối thiểu 8 ký tự', icon: Icons.lock_outline_rounded, obscureText: _obscure, suffix: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _navy)), validator: (value) => value == null || value.length < 6 ? 'Mật khẩu tối thiểu 6 ký tự' : null),
          const SizedBox(height: 11),
          Row(children: [const Icon(Icons.check_box, size: 19), const SizedBox(width: 7), const Text('Ghi nhớ đăng nhập', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))), const Spacer(), TextButton(onPressed: () {}, child: const Text('Quên mật khẩu?', style: TextStyle(fontSize: 11, color: _gold, fontWeight: FontWeight.w700)))]),
          const SizedBox(height: 6),
          SizedBox(height: 56, child: FilledButton(onPressed: authProvider.isLoading ? null : _login, style: FilledButton.styleFrom(backgroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: authProvider.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Đăng nhập ngay  →', style: TextStyle(fontWeight: FontWeight.w800)))),
          const SizedBox(height: 21),
          const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('HOẶC TIẾP TỤC VỚI', style: TextStyle(fontSize: 10, color: Color(0xFF64748B)))), Expanded(child: Divider())]),
          const SizedBox(height: 18),
          Row(children: [_social('G', 'Google', const Color(0xFFF3F6FF)), const SizedBox(width: 8), _social('', 'Apple', const Color(0xFFF3F6FF)), const SizedBox(width: 8), _social('f', 'Facebook', const Color(0xFFF3F6FF))]),
        ]),
      );

  Widget _social(String icon, String label, Color color) => Expanded(child: Container(height: 48, alignment: Alignment.center, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)), child: Text('$icon  $label', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700))));

  Widget _registerOffer() => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFFFE9DC), borderRadius: BorderRadius.circular(12)), child: Column(children: [const Row(children: [CircleAvatar(backgroundColor: _gold, child: Icon(Icons.card_giftcard, color: Colors.white, size: 20)), SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Chưa có tài khoản LuxeStay?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)), Text('Đăng ký ngay nhận voucher 500.000đ', style: TextStyle(fontSize: 10, color: Color(0xFF64748B)))]))]), const SizedBox(height: 12), SizedBox(width: double.infinity, height: 34, child: FilledButton(onPressed: _openRegister, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4A1C05), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: const Text('Nhận ưu đãi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700))) )]));

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: _navy,
        ),
        suffixIcon: suffix,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(color: _navy, fontWeight: FontWeight.w600, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFFF0F4FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE4E0D8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: _navy,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.redAccent,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
