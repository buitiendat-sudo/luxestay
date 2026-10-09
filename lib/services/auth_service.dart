import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleInitialized = false;

  /// Đăng ký tài khoản
  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    // 1. Tạo tài khoản trên Firebase Authentication
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw Exception('Không thể tạo tài khoản');
    }

    // Cập nhật tên hiển thị trên Firebase Auth.
    await user.updateDisplayName(name.trim());

    return credential;
  }

  /// Đăng nhập
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Gửi email đặt lại mật khẩu
  Future<void> resetPassword({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Đăng nhập bằng Google
  Future<UserCredential> signInWithGoogle() async {
    if (!_googleInitialized) {
      await _googleSignIn.initialize();
      _googleInitialized = true;
    }

    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  /// Đăng nhập bằng Facebook
  Future<UserCredential> signInWithFacebook() async {
    final loginResult = await FacebookAuth.instance.login();

    if (loginResult.status != LoginStatus.success ||
        loginResult.accessToken == null) {
      throw FirebaseAuthException(
        code: loginResult.status == LoginStatus.cancelled
            ? 'ERROR_ABORTED_BY_USER'
            : 'ERROR_FACEBOOK_LOGIN_FAILED',
        message:
            loginResult.message ??
            'Đăng nhập Facebook đã bị hủy hoặc thất bại.',
      );
    }

    final credential = FacebookAuthProvider.credential(
      loginResult.accessToken!.tokenString,
    );

    return _auth.signInWithCredential(credential);
  }

  /// Đăng xuất
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Người dùng hiện tại
  User? get currentUser => _auth.currentUser;

  /// Lấy thông tin user từ Firestore
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData(String uid) {
    return _db.collection('users').doc(uid).get();
  }
}
