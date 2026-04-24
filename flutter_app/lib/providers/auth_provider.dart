import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/socket_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null && _token != null;

  final _api = ApiService();
  final _storage = StorageService();
  final _socket = SocketService();

  Future<void> initialize() async {
    _setLoading(true);
    try {
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty) {
        _token = token;
        final data = await _api.get('/auth/me');
        if (data != null) {
          final userData = data['user'] ?? data;
          _currentUser = User.fromJson(userData as Map<String, dynamic>);
          _socket.connect(token);
        } else {
          await _clearAuth();
        }
      }
    } catch (e) {
      await _clearAuth();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    _setError(null);
    try {
      final data = await _api.post('/auth/login', {
        'email': email.trim(),
        'password': password,
      });

      final token = data['token']?.toString() ?? '';
      final userData = data['user'] ?? data;

      if (token.isEmpty) throw Exception('No token received');

      _token = token;
      _currentUser = User.fromJson(userData as Map<String, dynamic>);

      await _storage.saveToken(token);
      await _storage.saveUserId(_currentUser!.id);

      _socket.connect(token);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(
    String name,
    String email,
    String? phone,
    String password,
  ) async {
    _setLoading(true);
    _setError(null);
    try {
      final body = <String, dynamic>{
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      };
      if (phone != null && phone.trim().isNotEmpty) {
        body['phone'] = phone.trim();
      }

      final data = await _api.post('/auth/register', body);

      final token = data['token']?.toString() ?? '';
      final userData = data['user'] ?? data;

      if (token.isEmpty) throw Exception('No token received');

      _token = token;
      _currentUser = User.fromJson(userData as Map<String, dynamic>);

      await _storage.saveToken(token);
      await _storage.saveUserId(_currentUser!.id);

      _socket.connect(token);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _api.post('/auth/logout', {});
    } catch (_) {
      // Ignore errors on logout
    }
    await _clearAuth();
    _setLoading(false);
  }

  Future<void> _clearAuth() async {
    _socket.dispose();
    await _storage.clearAll();
    _token = null;
    _currentUser = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void updateCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }
}
