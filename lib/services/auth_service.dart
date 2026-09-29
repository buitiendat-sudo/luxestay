import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  /// Đăng xuất
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Người dùng hiện tại
  User? get currentUser => _auth.currentUser;

  /// Lấy thông tin user từ Firestore
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData(
    String uid,
  ) {
    return _db.collection('users').doc(uid).get();
  }
}