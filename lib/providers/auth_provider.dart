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
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) async {
      _user = user;

      if (user == null) {
        _role = 'CUSTOMER';
        _propertyId = null;
        _ownerOnboardingComplete = false;
        _ownerOnboardingJustCompleted = false;
        _isCheckingRole = false;
        notifyListeners();
        return;
      }

      await _loadUserRole(user.uid);
    });
  }

  // ============================================================
  // SERVICES
  // ============================================================

  final AuthService _authService = AuthService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // DATA
  // ============================================================

  User? _user;

  bool _isLoading = false;

  bool _isCheckingRole = false;

  String? _errorMessage;

  String _role = 'CUSTOMER';
  String? _propertyId;
  bool _ownerOnboardingComplete = false;
  bool _ownerOnboardingJustCompleted = false;

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

  bool get isOwner => _role == 'OWNER';

  bool get isCustomer => _role == 'CUSTOMER';

  String? get propertyId => _propertyId;

  bool get ownerOnboardingComplete => _ownerOnboardingComplete;

  bool consumeOwnerOnboardingSuccess() {
    final completed = _ownerOnboardingJustCompleted;
    _ownerOnboardingJustCompleted = false;
    return completed;
  }
  // ============================================================
  // REGISTER
  // ============================================================

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String role = 'CUSTOMER',
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
        _errorMessage = 'Không thể tạo tài khoản.';

        return false;
      }

      final normalizedRole = role.toUpperCase();
      if (normalizedRole != 'CUSTOMER' && normalizedRole != 'OWNER') {
        throw ArgumentError.value(
          role,
          'role',
          'Unsupported registration role',
        );
      }

      final uid = _user!.uid;
      final userReference = _firestore.collection('users').doc(uid);
      final batch = _firestore.batch();
      final userData = <String, dynamic>{
        'uid': uid,
        'name': name.trim(),
        'displayName': name,
        'email': email.trim(),
        'phone': '',
        'avatar': '',
        'role': normalizedRole,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (normalizedRole == 'OWNER') {
        userData['ownerOnboardingComplete'] = false;
      }

      batch.set(userReference, userData, SetOptions(merge: true));
      await batch.commit();
      _role = normalizedRole;
      _propertyId = null;
      _ownerOnboardingComplete = normalizedRole != 'OWNER';

      notifyListeners();

      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e);

      return false;
    } catch (e) {
      if (_user != null) {
        try {
          await _user!.delete();
        } on FirebaseAuthException catch (deleteError) {
          debugPrint(
            'Unable to roll back failed registration: ${deleteError.code}',
          );
        }
        _user = null;
        _role = 'CUSTOMER';
        _propertyId = null;
        _ownerOnboardingComplete = false;
      }
      _errorMessage = 'Đã xảy ra lỗi: $e';

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> completeOwnerOnboarding({
    required String propertyName,
    required String propertyLocation,
    required String propertyAddress,
    required String propertyDescription,
    required String propertyPhone,
    required String propertyImageUrl,
    required String signedName,
    required String agreementVersion,
    required String agreementText,
  }) async {
    final currentUser = _user;
    final cleanPropertyName = propertyName.trim();
    final cleanLocation = propertyLocation.trim();
    final cleanAddress = propertyAddress.trim();
    final cleanDescription = propertyDescription.trim();
    final cleanPhone = propertyPhone.trim();
    final cleanSignedName = signedName.trim();

    if (currentUser == null || !isOwner) {
      _errorMessage = 'Chỉ chủ khách sạn đã đăng nhập mới có thể tiếp tục.';
      notifyListeners();
      return false;
    }
    if (cleanPropertyName.isEmpty ||
        cleanLocation.isEmpty ||
        cleanAddress.isEmpty ||
        cleanSignedName.isEmpty ||
        agreementVersion.trim().isEmpty ||
        agreementText.trim().isEmpty) {
      _errorMessage = 'Vui lòng hoàn tất thông tin và chấp thuận điều khoản.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      final userReference = _firestore.collection('users').doc(currentUser.uid);
      final existingProfile = await userReference.get();
      final profile = existingProfile.data();
      if (!existingProfile.exists ||
          profile?['role']?.toString().toUpperCase() != 'OWNER') {
        throw StateError('Không tìm thấy hồ sơ chủ khách sạn hợp lệ.');
      }
      if (profile?['propertyId'] != null &&
          profile!['propertyId'].toString().isNotEmpty) {
        throw StateError('Tài khoản này đã được liên kết với khách sạn.');
      }

      final propertyReference = _firestore.collection('properties').doc();
      final batch = _firestore.batch();
      batch.set(propertyReference, {
        'name': cleanPropertyName,
        'location': cleanLocation,
        'address': cleanAddress,
        'description': cleanDescription,
        'phone': cleanPhone,
        'image': propertyImageUrl.trim(),
        'rating': 0,
        'reviewCount': 0,
        'pricePerNight': 0,
        'amenities': <String>[],
        'category': 'Hotel',
        'ownerId': currentUser.uid,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      batch.update(userReference, {
        'propertyId': propertyReference.id,
        'ownerOnboardingComplete': true,
        'ownerAgreementAccepted': true,
        'ownerAgreementVersion': agreementVersion.trim(),
        'ownerAgreementSignedName': cleanSignedName,
        'ownerAgreementText': agreementText.trim(),
        'ownerAgreementAcceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();

      _propertyId = propertyReference.id;
      _ownerOnboardingComplete = true;
      _ownerOnboardingJustCompleted = true;
      notifyListeners();
      return true;
    } on FirebaseException catch (error) {
      _errorMessage =
          'Không thể lưu hồ sơ khách sạn: ${error.message ?? error.code}';
      return false;
    } catch (error) {
      _errorMessage = 'Không thể hoàn tất đăng ký chủ khách sạn: $error';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);

    _errorMessage = null;

    try {
      final credential = await _authService.login(
        email: email,
        password: password,
      );

      _user = credential.user;

      if (_user == null) {
        _errorMessage = 'Không thể đăng nhập.';

        return false;
      }

      await _loadUserRole(_user!.uid);

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

  Future<bool> resetPassword({required String email}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      if (email.trim().isEmpty || !email.contains('@')) {
        _errorMessage = 'Vui lòng nhập email hợp lệ.';
        return false;
      }

      await _authService.resetPassword(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e);
      return false;
    } catch (e) {
      _errorMessage = 'Không thể gửi email đặt lại mật khẩu: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final credential = await _authService.signInWithGoogle();
      _user = credential.user;

      if (_user == null) {
        _errorMessage = 'Không thể đăng nhập bằng Google.';
        return false;
      }

      await _createUserDocumentIfNeeded(uid: _user!.uid);
      await _loadUserRole(_user!.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e);
      return false;
    } catch (e) {
      _errorMessage = 'Đăng nhập Google thất bại: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginWithFacebook() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final credential = await _authService.signInWithFacebook();
      _user = credential.user;

      if (_user == null) {
        _errorMessage = 'Không thể đăng nhập bằng Facebook.';
        return false;
      }

      await _createUserDocumentIfNeeded(uid: _user!.uid);
      await _loadUserRole(_user!.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e);
      return false;
    } catch (e) {
      _errorMessage = 'Đăng nhập Facebook thất bại: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOAD USER ROLE
  // ============================================================

  Future<void> _loadUserRole(String uid) async {
    _isCheckingRole = true;

    notifyListeners();

    try {
      final document = await _firestore.collection('users').doc(uid).get();

      // ========================================================
      // USER DOCUMENT EXISTS
      // ========================================================

      if (document.exists) {
        _ownerOnboardingJustCompleted = false;
        final data = document.data();

        final firestoreRole = data?['role']?.toString().trim().toUpperCase();

        if (firestoreRole == 'ADMIN') {
          _role = 'ADMIN';
          _propertyId = null;
          _ownerOnboardingComplete = false;
        } else if (firestoreRole == 'OWNER') {
          _role = 'OWNER';
          _propertyId = data?['propertyId']?.toString();
          _ownerOnboardingComplete =
              data?['ownerOnboardingComplete'] == true ||
              (_propertyId != null && _propertyId!.isNotEmpty);
        } else {
          _role = 'CUSTOMER';
          _propertyId = null;
          _ownerOnboardingComplete = false;
        }
      }
      // ========================================================
      // USER DOCUMENT DOES NOT EXIST
      // ========================================================
      else {
        _role = 'CUSTOMER';
        _propertyId = null;
        _ownerOnboardingComplete = false;
        _ownerOnboardingJustCompleted = false;

        await _createUserDocumentIfNeeded(uid: uid);
      }
    } on FirebaseException catch (e) {
      debugPrint('Firestore role error: ${e.code} - ${e.message}');

      // Nếu không đọc được role,
      // tuyệt đối không cấp quyền ADMIN.
      _role = 'CUSTOMER';
      _propertyId = null;
      _ownerOnboardingComplete = false;
    } catch (e) {
      debugPrint('Không thể đọc role người dùng: $e');

      _role = 'CUSTOMER';
      _propertyId = null;
      _ownerOnboardingComplete = false;
    } finally {
      _isCheckingRole = false;

      notifyListeners();
    }
  }

  // ============================================================
  // CREATE USER DOCUMENT IF NOT EXISTS
  // ============================================================

  Future<void> _createUserDocumentIfNeeded({required String uid}) async {
    final currentUser = _user;

    if (currentUser == null) {
      return;
    }

    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': currentUser.displayName ?? '',
        'displayName': currentUser.displayName ?? '',
        'email': currentUser.email ?? '',
        'phone': '',
        'avatar': '',
        'role': 'CUSTOMER',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      debugPrint('Create user error: ${e.code} - ${e.message}');
    } catch (e) {
      debugPrint('Không thể tạo Firestore user: $e');
    }
  }

  // ============================================================
  // REFRESH ROLE
  // ============================================================

  Future<void> refreshRole() async {
    final currentUser = _user;

    if (currentUser == null) {
      _role = 'CUSTOMER';
      _propertyId = null;
      _ownerOnboardingComplete = false;

      notifyListeners();

      return;
    }

    await _loadUserRole(currentUser.uid);
  }

  // ============================================================
  // RELOAD CURRENT USER
  // ============================================================

  Future<void> reloadUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    try {
      await currentUser.reload();

      _user = FirebaseAuth.instance.currentUser;

      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e);

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

      _role = 'CUSTOMER';
      _propertyId = null;
      _ownerOnboardingComplete = false;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getFirebaseErrorMessage(e);
    } catch (e) {
      _errorMessage = 'Không thể đăng xuất: $e';
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

  void _setLoading(bool value) {
    _isLoading = value;

    notifyListeners();
  }

  // ============================================================
  // FIREBASE ERROR MESSAGE
  // ============================================================

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

      case 'user-disabled':
        return 'Tài khoản này đã bị vô hiệu hóa.';

      case 'too-many-requests':
        return 'Có quá nhiều lần thử. Vui lòng thử lại sau.';

      case 'network-request-failed':
        return 'Không có kết nối mạng.';

      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này chưa được bật.';

      default:
        return e.message ?? 'Đăng nhập/đăng ký thất bại.';
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
