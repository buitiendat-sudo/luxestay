import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _user = _authService.currentUser;

    FirebaseAuth.instance.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

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
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e);
      return false;
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final credential = await _authService.login(
        email: email,
        password: password,
      );

      _user = credential.user;
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e);
      return false;
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
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

      case 'too-many-requests':
        return 'Có quá nhiều lần thử. Vui lòng thử lại sau.';

      case 'network-request-failed':
        return 'Không có kết nối mạng.';

      default:
        return e.message ?? 'Đăng nhập/đăng ký thất bại.';
    }
  }
}