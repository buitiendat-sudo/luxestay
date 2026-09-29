import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _user = _authService.currentUser;

    // Nếu mở lại app mà user vẫn còn phiên đăng nhập
    if (_user != null) {
      _loadUserRole(_user!.uid);
    }

    // Theo dõi trạng thái đăng nhập / đăng xuất
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen(
      (user) async {
        _user = user;

        if (user == null) {
          _role = 'CUSTOMER';
          _isCheckingRole = false;
          notifyListeners();
          return;
        }

        await _loadUserRole(user.uid);
      },
    );
  }

  // ============================================================
  // SERVICES
  // ============================================================

  final AuthService _authService = AuthService();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // DATA
  // ============================================================

  User? _user;

  bool _isLoading = false;

  bool _isCheckingRole = false;

  String? _errorMessage;

  String _role = 'CUSTOMER';

  StreamSubscription<User?>? _authSubscription;

  // ============================================================
  // GETTERS
  // ============================================================

  User? get user => _user;

  bool get isLoading => _isLoading;

  bool get isCheckingRole => _isCheckingRole;

  String? get errorMessage => _errorMessage;

  String get role => _role;

  bool get isLoggedIn => _user != null;

  bool get isAdmin => _role == 'ADMIN';

  bool get isCustomer => _role == 'CUSTOMER';

  // ============================================================
  // REGISTER
  // ============================================================

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    _errorMessage = null;

    try {
      final credential = await _authService.register(
        name: name,
        email: email,
        password: password,
      );

      _user = credential.user;

      if (_user == null) {
        _errorMessage =
            'Không thể tạo tài khoản.';

        return false;
      }

      // Người đăng ký trực tiếp từ app
      // mặc định luôn là CUSTOMER.
      _role = 'CUSTOMER';

      // Tạo document user theo đúng Firebase Auth UID.
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .set(
        {
          'uid': _user!.uid,
          'name': name.trim(),
          'displayName': name,
          'email': email.trim(),
          'phone': '',
          'avatar': '',
          'role': 'CUSTOMER',
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      notifyListeners();

      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage =
          _getFirebaseErrorMessage(e);

      return false;
    } catch (e) {
      _errorMessage =
          'Đã xảy ra lỗi: $e';

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    _errorMessage = null;

    try {
      final credential =
          await _authService.login(
        email: email,
        password: password,
      );

      _user = credential.user;

      if (_user == null) {
        _errorMessage =
            'Không thể đăng nhập.';

        return false;
      }

      // Sau khi Firebase Authentication xác thực thành công,
      // đọc role từ:
      //
      // users/{FirebaseAuth UID}
      //
      await _loadUserRole(
        _user!.uid,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage =
          _getFirebaseErrorMessage(e);

      return false;
    } catch (e) {
      _errorMessage =
          'Đã xảy ra lỗi: $e';

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOAD USER ROLE
  // ============================================================

  Future<void> _loadUserRole(
    String uid,
  ) async {
    _isCheckingRole = true;

    notifyListeners();

    try {
      final document =
          await _firestore
              .collection('users')
              .doc(uid)
              .get();

      // ========================================================
      // USER DOCUMENT EXISTS
      // ========================================================

      if (document.exists) {
        final data = document.data();

        final firestoreRole =
            data?['role']
                ?.toString()
                .trim()
                .toUpperCase();

        // Chỉ chấp nhận ADMIN.
        // Tất cả role khác mặc định CUSTOMER.
        if (firestoreRole == 'ADMIN') {
          _role = 'ADMIN';
        } else {
          _role = 'CUSTOMER';
        }
      }

      // ========================================================
      // USER DOCUMENT DOES NOT EXIST
      // ========================================================

      else {
        _role = 'CUSTOMER';

        await _createUserDocumentIfNeeded(
          uid: uid,
        );
      }
    } on FirebaseException catch (e) {
      debugPrint(
        'Firestore role error: ${e.code} - ${e.message}',
      );

      // Nếu không đọc được role,
      // tuyệt đối không cấp quyền ADMIN.
      _role = 'CUSTOMER';
    } catch (e) {
      debugPrint(
        'Không thể đọc role người dùng: $e',
      );

      _role = 'CUSTOMER';
    } finally {
      _isCheckingRole = false;

      notifyListeners();
    }
  }

  // ============================================================
  // CREATE USER DOCUMENT IF NOT EXISTS
  // ============================================================

  Future<void> _createUserDocumentIfNeeded({
    required String uid,
  }) async {
    final currentUser = _user;

    if (currentUser == null) {
      return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .set(
        {
          'displayName':
              currentUser.displayName ?? '',
          'email':
              currentUser.email ?? '',
          'phone': '',
          'avatar': '',
          'role': 'CUSTOMER',
          'createdAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint(
        'Create user error: ${e.code} - ${e.message}',
      );
    } catch (e) {
      debugPrint(
        'Không thể tạo Firestore user: $e',
      );
    }
  }

  // ============================================================
  // REFRESH ROLE
  // ============================================================

  Future<void> refreshRole() async {
    final currentUser = _user;

    if (currentUser == null) {
      _role = 'CUSTOMER';

      notifyListeners();

      return;
    }

    await _loadUserRole(
      currentUser.uid,
    );
  }

  // ============================================================
  // RELOAD CURRENT USER
  // ============================================================

  Future<void> reloadUser() async {
    final currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    try {
      await currentUser.reload();

      _user =
          FirebaseAuth.instance.currentUser;

      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _errorMessage =
          _getFirebaseErrorMessage(e);

      notifyListeners();
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    _setLoading(true);

    _errorMessage = null;

    try {
      await _authService.logout();

      _user = null;

      // Reset quyền sau logout.
      _role = 'CUSTOMER';
    } on FirebaseAuthException catch (e) {
      _errorMessage =
          _getFirebaseErrorMessage(e);
    } catch (e) {
      _errorMessage =
          'Không thể đăng xuất: $e';
    } finally {
      _setLoading(false);

      notifyListeners();
    }
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // SET LOADING
  // ============================================================

  void _setLoading(
    bool value,
  ) {
    _isLoading = value;

    notifyListeners();
  }

  // ============================================================
  // FIREBASE ERROR MESSAGE
  // ============================================================

  String _getFirebaseErrorMessage(
    FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email này đã được sử dụng.';

      case 'invalid-email':
        return 'Email không hợp lệ.';

      case 'weak-password':
        return 'Mật khẩu quá yếu.';

      case 'user-not-found':
        return 'Không tìm thấy tài khoản.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không chính xác.';

      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';

      case 'too-many-requests':
        return 'Có quá nhiều lần thử. Vui lòng thử lại sau.';

      case 'network-request-failed':
        return 'Không có kết nối mạng.';

      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này chưa được bật.';

      default:
        return e.message ??
            'Đăng nhập/đăng ký thất bại.';
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _authSubscription?.cancel();

    super.dispose();
  }
}