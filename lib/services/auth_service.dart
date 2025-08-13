import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/client.dart';
import '../models/admin.dart';
import 'api_service.dart';

class AuthService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _rememberMeKey = 'remember_me';

  // Current user data
  static Client? _currentClient;
  static Admin? _currentAdmin;
  static String? _currentToken;

  // Getters
  static Client? get currentClient => _currentClient;
  static Admin? get currentAdmin => _currentAdmin;
  static String? get currentToken => _currentToken;
  static bool get isAuthenticated => _currentToken != null;

  /// Initialize authentication service
  static Future<void> initialize() async {
    try {
      // Check if user is already logged in
      final token = await _secureStorage.read(key: _tokenKey);
      if (token != null) {
        _currentToken = token;
        await _loadUserData();
        
        // Update API service with the token
        ApiService.setAuthToken(token);
      }
    } catch (e) {
      print('Error initializing auth service: $e');
    }
  }

  /// Login with email/phone and password
  static Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
    bool rememberMe = false,
    String? deviceToken,
  }) async {
    try {
      final response = await ApiService.login(emailOrPhone, password);

      if (response['success'] == true) {
        final token = response['data']['token'];
        final clientData = response['data']['client'];

        // Store token securely
        await _secureStorage.write(key: _tokenKey, value: token);
        _currentToken = token;

        // Store user data
        if (clientData != null) {
          _currentClient = Client.fromJson(clientData);
          await _saveUserData();
        }

        // Store remember me preference
        await _secureStorage.write(
          key: _rememberMeKey,
          value: rememberMe.toString(),
        );

        return {
          'success': true,
          'message': 'Login successful',
          'client': _currentClient,
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Register new user
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    String? city,
    String? address,
    DateTime? dob,
    DateTime? weddingAnniversary,
  }) async {
    try {
      if (password != confirmPassword) {
        return {'success': false, 'message': 'Passwords do not match'};
      }

      final userData = {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': confirmPassword,
        'city': city,
        'address': address,
        'dob': dob?.toIso8601String(),
        'wedding_anniversary': weddingAnniversary?.toIso8601String(),
      };

      final response = await ApiService.register(userData);

      if (response['success'] == true) {
        return {
          'success': true,
          'message':
              'Registration successful. Please check your email for verification.',
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Logout user
  static Future<void> logout() async {
    try {
      // Call logout API if token exists
      if (_currentToken != null) {
        try {
          await ApiService.logout();
        } catch (e) {
          // Continue with local logout even if API call fails
          print('Logout API call failed: $e');
        }
      }

      // Clear local data
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _userDataKey);

      // Clear memory
      _currentToken = null;
      _currentClient = null;
      _currentAdmin = null;

      // Clear API service token
      ApiService.clearAuthToken();

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  /// Check if biometric authentication is available
  static Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Enable biometric authentication
  static Future<bool> enableBiometric() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to enable biometric login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        await _secureStorage.write(key: _biometricEnabledKey, value: 'true');
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Disable biometric authentication
  static Future<void> disableBiometric() async {
    await _secureStorage.delete(key: _biometricEnabledKey);
  }

  /// Check if biometric is enabled
  static Future<bool> isBiometricEnabled() async {
    final enabled = await _secureStorage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }

  /// Authenticate with biometrics
  static Future<bool> authenticateWithBiometrics() async {
    try {
      final isEnabled = await isBiometricEnabled();
      if (!isEnabled) return false;

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your account',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      return authenticated;
    } catch (e) {
      return false;
    }
  }

  /// Forgot password
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await ApiService.forgotPassword(email);

      if (response['success'] == true) {
        return {
          'success': true,
          'message': 'Password reset link sent to your email',
        };
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Failed to send reset link',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Reset password
  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      if (password != confirmPassword) {
        return {'success': false, 'message': 'Passwords do not match'};
      }

      final response = await ApiService.resetPassword(
        token: token,
        password: password,
        passwordConfirmation: confirmPassword,
      );

      if (response['success'] == true) {
        return {'success': true, 'message': 'Password reset successful'};
      } else {
        return {
          'success': false,
          'message': response['message'] ?? 'Password reset failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Refresh authentication token
  static Future<bool> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await ApiService.refreshToken();

      if (response['success'] == true) {
        final newToken = response['data']['token'];
        await _secureStorage.write(key: _tokenKey, value: newToken);
        _currentToken = newToken;
        
        // Update API service with new token
        ApiService.setAuthToken(newToken);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if token is expired
  static bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final exp = payload['exp'] as int?;
      if (exp == null) return true;

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      return true;
    }
  }

  /// Save user data to secure storage
  static Future<void> _saveUserData() async {
    if (_currentClient != null) {
      await _secureStorage.write(
        key: _userDataKey,
        value: json.encode(_currentClient!.toJson()),
      );
    }
  }

  /// Load user data from secure storage
  static Future<void> _loadUserData() async {
    try {
      final userData = await _secureStorage.read(key: _userDataKey);
      if (userData != null) {
        final data = json.decode(userData);
        _currentClient = Client.fromJson(data);
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  /// Clear all stored data
  static Future<void> clearAllData() async {
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    // Clear API service token
    ApiService.clearAuthToken();
  }
}
