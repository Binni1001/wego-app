import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../shared/models/user_model.dart';
import '../../../core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get firebaseUser => _auth.currentUser;
  UserModel? _userModel;
  UserModel? get userModel => _userModel;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user != null) {
      await _fetchUserModel(user.uid);
    } else {
      _userModel = null;
    }
    notifyListeners();
  }

  Future<void> _fetchUserModel(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (doc.exists) {
      _userModel = UserModel.fromMap(doc.data()!);
    }
  }

  // Đăng nhập Google
  Future<String?> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Dùng GoogleSignIn thay vì signInWithPopup
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser =
      await googleSignIn.signIn();

      // Người dùng huỷ đăng nhập
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return 'Đã huỷ đăng nhập';
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      final user = userCredential.user;
      if (user == null) return 'Đăng nhập thất bại';

      // Kiểm tra user đã tồn tại chưa
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        return 'new_user';
      }

      await _fetchUserModel(user.uid);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Lưu user mới với role đã chọn
  Future<void> saveNewUser(String name, String phone, String role) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final newUser = UserModel(
      uid: user.uid,
      name: name,
      phone: phone,
      role: role,
      avatarUrl: user.photoURL,
    );

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(newUser.toMap());

    _userModel = newUser;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _userModel = null;
    notifyListeners();
  }
}