import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

const _navy = Color(0xFF0F172A);
const _gold = Color(0xFFD97706);
const _background = Color(0xFFF8F9FF);

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.resetPassword(
      email: _emailController.text.trim(),
    );
    if (!mounted) return;

    setState(() => _emailSent = success);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Email đặt lại mật khẩu đã được gửi.'
                : auth.errorMessage ?? 'Không thể gửi email đặt lại mật khẩu.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Đặt lại mật khẩu'),
        backgroundColor: _background,
        foregroundColor: _navy,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) => Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.lock_reset_rounded,
                        size: 54,
                        color: _gold,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Bạn quên mật khẩu?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _navy,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Nhập email tài khoản để nhận liên kết tạo mật khẩu mới.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF64748B), height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Email tài khoản',
                          hintText: 'name@example.com',
                          prefixIcon: Icon(Icons.alternate_email_rounded),
                          filled: true,
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(email)) {
                            return 'Vui lòng nhập email hợp lệ.';
                          }
                          return null;
                        },
                        onChanged: (_) {
                          if (_emailSent) setState(() => _emailSent = false);
                        },
                        onFieldSubmitted: (_) => auth.isLoading
                            ? null
                            : _sendResetEmail(),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: auth.isLoading ? null : _sendResetEmail,
                          icon: auth.isLoading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            auth.isLoading ? 'Đang gửi...' : 'Gửi liên kết đặt lại',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _navy,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      if (_emailSent) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Hãy kiểm tra hộp thư đến và thư mục spam của bạn.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF166534)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}