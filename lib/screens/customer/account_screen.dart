import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/firestore_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  // ============================================================
  // CONSTANTS
  // ============================================================

  static const Color _navy = Color(0xFF0F172A);
  static const Color _background = Color(0xFFF8F7F3);

  // ============================================================
  // STATE
  // ============================================================

  String _phone = '';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ============================================================
  // LOAD PROFILE FROM FIRESTORE
  // ============================================================

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      final firestoreService =
          context.read<FirestoreService>();

      final snapshot = await firestoreService.users
          .doc(user.uid)
          .get();

      final data = snapshot.data();

      if (data != null) {
        final phone = data['phone'] as String? ?? '';

        if (!mounted) {
          return;
        }

        setState(() {
          _phone = phone;
        });
      }
    } catch (_) {
      // Nếu users/{uid} chưa tồn tại,
      // vẫn cho phép người dùng sử dụng tài khoản.
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: _background,
        body: _LoginRequiredState(),
      );
    }

    final displayName =
        user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'Khách hàng';

    final email =
        user.email?.trim().isNotEmpty == true
            ? user.email!.trim()
            : 'Chưa cập nhật email';

    final initial = displayName
        .trim()
        .substring(0, 1)
        .toUpperCase();

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ==================================================
            // HEADER
            // ==================================================

            SliverToBoxAdapter(
              child: _buildProfileHeader(
                displayName: displayName,
                email: email,
                initial: initial,
              ),
            ),

            // ==================================================
            // CONTENT
            // ==================================================

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                30,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    // ==================================================
                    // ACCOUNT
                    // ==================================================

                    const _SectionTitle(
                      title: 'Tài khoản',
                    ),

                    _AccountCard(
                      children: [
                        _AccountItem(
                          icon:
                              Icons.person_outline_rounded,
                          title: 'Thông tin cá nhân',
                          subtitle:
                              'Chỉnh sửa tên và số điện thoại',
                          onTap: () {
                            _showEditProfile(user);
                          },
                        ),
                        const _ItemDivider(),
                        _AccountItem(
                          icon:
                              Icons.lock_outline_rounded,
                          title: 'Bảo mật',
                          subtitle:
                              'Thông tin bảo mật tài khoản',
                          onTap: () {
                            _showSecurityInfo();
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // ==================================================
                    // APPLICATION
                    // ==================================================

                    const _SectionTitle(
                      title: 'Ứng dụng',
                    ),

                    _AccountCard(
                      children: [
                        _AccountItem(
                          icon:
                              Icons.notifications_none_rounded,
                          title: 'Thông báo',
                          subtitle:
                              'Quản lý thông báo của LuxeStay',
                          trailing:
                              const _ComingSoonBadge(),
                          onTap: () {
                            _showComingSoon(
                              'Thông báo',
                            );
                          },
                        ),
                        const _ItemDivider(),
                        _AccountItem(
                          icon:
                              Icons.help_outline_rounded,
                          title: 'Trợ giúp',
                          subtitle:
                              'Hướng dẫn sử dụng LuxeStay',
                          onTap: () {
                            _showHelp();
                          },
                        ),
                        const _ItemDivider(),
                        _AccountItem(
                          icon:
                              Icons.info_outline_rounded,
                          title: 'Về LuxeStay',
                          subtitle:
                              'Thông tin ứng dụng',
                          onTap: () {
                            _showAbout();
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // ==================================================
                    // LOGOUT
                    // ==================================================

                    _LogoutButton(
                      onTap: () {
                        _showLogoutDialog();
                      },
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // VERSION
                    // ==================================================

                    Center(
                      child: Text(
                        'LuxeStay • Luxury Resort Booking',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Center(
                      child: Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          color: Color(0xFFB0B0B0),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader({
    required String displayName,
    required String email,
    required String initial,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        12,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Tài khoản',
            style: TextStyle(
              color: _navy,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _navy.withValues(
                    alpha: 0.12,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                // AVATAR
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: 0.5,
                      ),
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                const SizedBox(width: 15),

                // USER INFORMATION
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Xin chào,',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                      if (_phone.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          _phone,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // EDIT BUTTON
                Material(
                  color: Colors.white.withValues(
                    alpha: 0.12,
                  ),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder:
                        const CircleBorder(),
                    onTap: () {
                      final currentUser =
                          FirebaseAuth
                              .instance
                              .currentUser;

                      if (currentUser != null) {
                        _showEditProfile(
                          currentUser,
                        );
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================

  Future<void> _showEditProfile(
    User user,
  ) async {
    final nameController =
        TextEditingController(
      text: user.displayName ?? '',
    );

    final phoneController =
        TextEditingController(
      text: _phone,
    );

    final firestoreService =
        context.read<FirestoreService>();

    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
            modalContext,
            setModalState,
          ) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(modalContext)
                        .viewInsets
                        .bottom +
                    25,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ========================================
                    // TITLE
                    // ========================================

                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFF1F5F9),
                            borderRadius:
                                BorderRadius.circular(
                              13,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: _navy,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chỉnh sửa thông tin',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight.w800,
                                  color: _navy,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Cập nhật thông tin cá nhân',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // ========================================
                    // NAME
                    // ========================================

                    const _FieldLabel(
                      text: 'Họ và tên',
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: nameController,
                      textCapitalization:
                          TextCapitalization.words,
                      textInputAction:
                          TextInputAction.next,
                      decoration:
                          _inputDecoration(
                        hintText:
                            'Nhập họ và tên',
                        icon:
                            Icons.person_outline,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ========================================
                    // PHONE
                    // ========================================

                    const _FieldLabel(
                      text: 'Số điện thoại',
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: phoneController,
                      keyboardType:
                          TextInputType.phone,
                      textInputAction:
                          TextInputAction.done,
                      decoration:
                          _inputDecoration(
                        hintText:
                            'Nhập số điện thoại',
                        icon:
                            Icons.phone_outlined,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ========================================
                    // EMAIL
                    // ========================================

                    const _FieldLabel(
                      text: 'Email',
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller:
                          TextEditingController(
                        text: user.email ?? '',
                      ),
                      readOnly: true,
                      decoration:
                          _inputDecoration(
                        hintText:
                            'Email tài khoản',
                        icon:
                            Icons.email_outlined,
                        readOnly: true,
                      ).copyWith(
                        suffixIcon: const Icon(
                          Icons.lock_outline,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      'Email được quản lý bởi Firebase Authentication.',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ========================================
                    // SAVE BUTTON
                    // ========================================

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: saving
                            ? null
                            : () async {
                                final name =
                                    nameController
                                        .text
                                        .trim();

                                final phone =
                                    phoneController
                                        .text
                                        .trim();

                                // VALIDATION
                                if (name.isEmpty) {
                                  ScaffoldMessenger
                                      .of(
                                    modalContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Vui lòng nhập họ và tên.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                if (phone.isNotEmpty &&
                                    !_isValidPhone(
                                      phone,
                                    )) {
                                  ScaffoldMessenger
                                      .of(
                                    modalContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Số điện thoại không hợp lệ.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() {
                                  saving = true;
                                });

                                try {
                                  // ==================================
                                  // UPDATE FIREBASE AUTH
                                  // ==================================

                                  await user
                                      .updateDisplayName(
                                    name,
                                  );

                                  // ==================================
                                  // UPDATE FIRESTORE
                                  // ==================================

                                  await firestoreService
                                      .setUser(
                                    user.uid,
                                    {
                                      'displayName':
                                          name,
                                      'email':
                                          user.email,
                                      'phone':
                                          phone,
                                    },
                                  );

                                  // ==================================
                                  // RELOAD USER
                                  // ==================================

                                  await user.reload();

                                  if (!mounted) {
                                    return;
                                  }

                                  setState(() {
                                    _phone = phone;
                                  });

                                  // ==================================
                                  // CLOSE MODAL
                                  // ==================================

                                  if (sheetContext
                                      .mounted) {
                                    Navigator.pop(
                                      sheetContext,
                                    );
                                  }

                                  // ==================================
                                  // SUCCESS MESSAGE
                                  // ==================================

                                  if (!mounted) {
                                    return;
                                  }

                                  ScaffoldMessenger
                                      .of(
                                    context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Cập nhật thông tin thành công.',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) {
                                    return;
                                  }

                                  setModalState(() {
                                    saving = false;
                                  });

                                  if (!modalContext
                                      .mounted) {
                                    return;
                                  }

                                  ScaffoldMessenger
                                      .of(
                                    modalContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Không thể cập nhật thông tin: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: _navy,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              Colors.grey.shade400,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                        ),
                        child: saving
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
                                'Lưu thay đổi',
                                style: TextStyle(
                                  fontWeight:
                                      FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
  }

  // ============================================================
  // PHONE VALIDATION
  // ============================================================

  bool _isValidPhone(String phone) {
    final cleanPhone =
        phone.replaceAll(
      RegExp(r'[\s\-]'),
      '',
    );

    return RegExp(
      r'^(0|\+84)[0-9]{9,10}$',
    ).hasMatch(cleanPhone);
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    bool readOnly = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(
        icon,
        color: _navy,
      ),
      filled: readOnly,
      fillColor:
          readOnly ? const Color(0xFFF1F5F9) : null,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _navy,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // SECURITY
  // ============================================================

  void _showSecurityInfo() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    size: 34,
                    color: _navy,
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  'Bảo mật tài khoản',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 9),

                Text(
                  'Tài khoản của bạn đang được xác thực và quản lý bởi Firebase Authentication.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 20),

                const _SecurityRow(
                  icon:
                      Icons.verified_user_outlined,
                  title: 'Xác thực tài khoản',
                  subtitle:
                      'Firebase Authentication',
                ),

                const SizedBox(height: 10),

                const _SecurityRow(
                  icon: Icons.lock_outline,
                  title: 'Mật khẩu',
                  subtitle:
                      'Được Firebase quản lý',
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style:
                        FilledButton.styleFrom(
                      backgroundColor: _navy,
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                    ),
                    child: const Text(
                      'Đã hiểu',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // HELP
  // ============================================================

  void _showHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trợ giúp',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),

                const SizedBox(height: 18),

                const _HelpRow(
                  icon: Icons.hotel_outlined,
                  title: 'Đặt phòng',
                  subtitle:
                      'Chọn resort → chọn phòng → chọn ngày → xác nhận đặt phòng.',
                ),

                const SizedBox(height: 13),

                const _HelpRow(
                  icon: Icons.favorite_border,
                  title: 'Yêu thích',
                  subtitle:
                      'Nhấn biểu tượng trái tim để lưu resort vào danh sách yêu thích.',
                ),

                const SizedBox(height: 13),

                const _HelpRow(
                  icon: Icons.luggage_outlined,
                  title: 'Chuyến đi',
                  subtitle:
                      'Theo dõi các đặt phòng đã tạo trong tài khoản của bạn.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ABOUT
  // ============================================================

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'LuxeStay',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _navy,
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.hotel_rounded,
          color: Colors.white,
        ),
      ),
      children: const [
        Text(
          'LuxeStay là ứng dụng đặt phòng resort và quản lý chuyến đi.',
        ),
      ],
    );
  }

  // ============================================================
  // COMING SOON
  // ============================================================

  void _showComingSoon(
    String feature,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$feature sẽ được phát triển ở phiên bản tiếp theo.',
        ),
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _showLogoutDialog() async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Đăng xuất',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Bạn có chắc muốn đăng xuất khỏi LuxeStay?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Hủy',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style:
                  FilledButton.styleFrom(
                backgroundColor: _navy,
              ),
              child: const Text(
                'Đăng xuất',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể đăng xuất: $e',
          ),
        ),
      );
    }
  }
}

// ============================================================
// SECTION TITLE
// ============================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 9,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ============================================================
// ACCOUNT CARD
// ============================================================

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

// ============================================================
// ACCOUNT ITEM
// ============================================================

class _AccountItem extends StatelessWidget {
  const _AccountItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF1F5F9),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color:
                      const Color(0xFF0F172A),
                  size: 21,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color:
                            Color(0xFF0F172A),
                        fontWeight:
                            FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DIVIDER
// ============================================================

class _ItemDivider extends StatelessWidget {
  const _ItemDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 70,
      ),
      child: Divider(
        height: 1,
        color: Colors.grey.shade200,
      ),
    );
  }
}

// ============================================================
// FIELD LABEL
// ============================================================

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Color(0xFF0F172A),
      ),
    );
  }
}

// ============================================================
// SECURITY ROW
// ============================================================

class _SecurityRow extends StatelessWidget {
  const _SecurityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Color(0xFF16A34A),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color:
                        Colors.grey.shade600,
                    fontSize: 11,
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

// ============================================================
// HELP ROW
// ============================================================

class _HelpRow extends StatelessWidget {
  const _HelpRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0F172A),
            size: 21,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight:
                      FontWeight.w700,
                  color:
                      Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  color:
                      Colors.grey.shade600,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// COMING SOON
// ============================================================

class _ComingSoonBadge
    extends StatelessWidget {
  const _ComingSoonBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius:
            BorderRadius.circular(7),
      ),
      child: const Text(
        'Sắp có',
        style: TextStyle(
          color: Color(0xFF64748B),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ============================================================
// LOGOUT BUTTON
// ============================================================

class _LogoutButton
    extends StatelessWidget {
  const _LogoutButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(
          Icons.logout_rounded,
          size: 19,
        ),
        label: const Text(
          'Đăng xuất',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        style:
            OutlinedButton.styleFrom(
          foregroundColor:
              const Color(0xFFB91C1C),
          side: const BorderSide(
            color: Color(0xFFFECACA),
          ),
          backgroundColor:
              const Color(0xFFFFF7F7),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// LOGIN REQUIRED
// ============================================================

class _LoginRequiredState
    extends StatelessWidget {
  const _LoginRequiredState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration:
                  BoxDecoration(
                color:
                    const Color(0xFFF1F5F9),
                borderRadius:
                    BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons
                    .person_outline_rounded,
                size: 42,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Vui lòng đăng nhập',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Đăng nhập để xem và quản lý tài khoản của bạn.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}