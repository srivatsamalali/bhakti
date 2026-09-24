import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';
import '../preferences/preferences_service.dart';

class AuthService extends ChangeNotifier {
  final PreferencesService _prefs;

  FirebaseAuth? _firebaseAuthInstance;
  FirebaseAuth? get _firebaseAuth {
    try {
      _firebaseAuthInstance ??= FirebaseAuth.instance;
      return _firebaseAuthInstance;
    } catch (_) {
      return null;
    }
  }

  bool _isAdminAuthenticated = false;
  String? _adminUsername;

  bool get isAdminAuthenticated => _isAdminAuthenticated;
  String? get adminUsername => _adminUsername;

  AuthService(this._prefs);

  /// Authenticate administrator with credentials
  Future<bool> loginAdmin(String username, String password) async {
    final cleanUser = username.trim().toLowerCase();
    final cleanPass = password.trim();

    // Check development / local configured credentials
    final isDevMatch = (cleanUser == AppConstants.defaultAdminUser) &&
        _prefs.verifyAdminPassword(cleanPass);

    if (isDevMatch) {
      _isAdminAuthenticated = true;
      _adminUsername = cleanUser;
      notifyListeners();
      return true;
    }

    // Attempt Firebase Auth sign-in if configured with admin email
    try {
      final fa = _firebaseAuth;
      if (fa != null && cleanUser.contains('@')) {
        final credential = await fa.signInWithEmailAndPassword(
          email: cleanUser,
          password: cleanPass,
        );
        if (credential.user != null) {
          _isAdminAuthenticated = true;
          _adminUsername = cleanUser;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Firebase Admin Auth exception: $e');
    }

    _isAdminAuthenticated = false;
    notifyListeners();
    return false;
  }

  /// Change administrator password
  Future<bool> changeAdminPassword(String oldPassword, String newPassword) async {
    if (!_isAdminAuthenticated) return false;
    if (_prefs.verifyAdminPassword(oldPassword)) {
      await _prefs.changeAdminPassword(newPassword);
      return true;
    }
    return false;
  }

  /// Admin logout
  Future<void> logoutAdmin() async {
    _isAdminAuthenticated = false;
    _adminUsername = null;
    try {
      await _firebaseAuth?.signOut();
    } catch (_) {}
    notifyListeners();
  }
}
