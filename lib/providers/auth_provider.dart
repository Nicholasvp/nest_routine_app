import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

enum SocialProvider { google, apple }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  AuthService get authService => _authService;

  AuthProvider() {
    _user = _authService.currentUser;
    _authService.authStateChanges.listen((authState) {
      _user = authState.session?.user;
      notifyListeners();
    });
  }

  Future<bool> signUp(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signUp(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signIn(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      debugPrint('[AuthProvider] signOut error: $e');
    }
    _user = null;
    notifyListeners();
  }

  /// Google / Apple sign in.
  ///
  /// Google opens an external browser, so success arrives later through
  /// [authStateChanges]. [error] stays null while the flow is pending and the
  /// caller should not show a failure dialog unless it returns false.
  Future<bool> signInWithProvider(SocialProvider provider) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      switch (provider) {
        case SocialProvider.google:
          await _authService.signInWithGoogle();
        case SocialProvider.apple:
          final response = await _authService.signInWithApple();
          _user = response.user ?? response.session?.user;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      if (_authService.isAppleCancellation(e)) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      debugPrint('[AuthProvider] ${provider.name} signIn error: $e');
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
