import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiService {
  static String? _authToken;
  static const Duration _timeout = Duration(seconds: 30);

  // Initialize auth token from AuthService
  static Future<void> initializeAuthToken() async {
    _authToken = AuthService.currentToken;
  }

  // Get current auth token
  static String? get authToken => _authToken;

  // Set auth token
  static void setAuthToken(String token) {
    _authToken = token;
  }

  // Clear auth token
  static void clearAuthToken() {
    _authToken = null;
  }

  // Generic HTTP request method with proper error handling
  static Future<Map<String, dynamic>> _makeRequest(
    String endpoint,
    Map<String, String> headers,
    dynamic body,
    String method,
  ) async {
    try {
      final uri = Uri.parse(ApiConfig.getEndpoint(endpoint));
      
      final request = http.Request(method, uri);
      request.headers.addAll(headers);
      
      if (body != null) {
        if (body is Map<String, dynamic>) {
          request.body = jsonEncode(body);
        } else if (body is String) {
          request.body = body;
        }
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error: ${e.message}');
      } else if (e is FormatException) {
        throw Exception('Invalid response format: ${e.message}');
      } else {
        throw Exception('Request failed: ${e.toString()}');
      }
    }
  }

  // Handle HTTP response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    
    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true, 'message': 'Operation completed successfully'};
      }
      
      try {
        final data = jsonDecode(response.body);
        return data is Map<String, dynamic> ? data : {'data': data};
      } catch (e) {
        throw Exception('Invalid response format: ${e.toString()}');
      }
    } else {
      final errorMessage = _getErrorMessage(response, statusCode);
      throw Exception(errorMessage);
    }
  }

  // Get error message from response
  static String _getErrorMessage(http.Response response, int statusCode) {
    try {
      final errorData = jsonDecode(response.body);
      if (errorData is Map<String, dynamic>) {
        return errorData['message'] ?? 
               errorData['error'] ?? 
               ApiConfig.getErrorMessage(statusCode);
      }
    } catch (e) {
      // Ignore JSON parsing errors
    }
    
    return ApiConfig.getErrorMessage(statusCode);
  }

  // Build headers for requests
  static Map<String, String> _buildHeaders({bool requiresAuth = true}) {
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    
    if (requiresAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  // Authentication Methods
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _makeRequest(
      ApiConfig.loginEndpoint,
      _buildHeaders(requiresAuth: false),
      {
        'email': email,
        'password': password,
        'device_name': 'flutter-client-portal',
        'device_token': await _getDeviceToken(),
      },
      'POST',
    );

    if (response['success'] == true && response['data'] != null) {
      final token = response['data']['token'];
      final clientData = response['data']['client'];
      
      // Set auth token
      setAuthToken(token);
      
      // Store client data in AuthService
      if (clientData != null) {
        // Update AuthService with the new token
        await AuthService.initialize();
      }
    }

    return response;
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    return await _makeRequest(
      ApiConfig.registerEndpoint,
      _buildHeaders(requiresAuth: false),
      userData,
      'POST',
    );
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      if (_authToken != null) {
        await _makeRequest(
          ApiConfig.logoutEndpoint,
          _buildHeaders(),
          {},
          'POST',
        );
      }
    } catch (e) {
      // Continue with local logout even if API call fails
      print('Logout API call failed: $e');
    } finally {
      clearAuthToken();
    }
    
    return {'success': true, 'message': 'Logged out successfully'};
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await _makeRequest(
      ApiConfig.forgotPasswordEndpoint,
      _buildHeaders(requiresAuth: false),
      {'email': email},
      'POST',
    );
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await _makeRequest(
      ApiConfig.resetPasswordEndpoint,
      _buildHeaders(requiresAuth: false),
      {
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      'POST',
    );
  }

  static Future<Map<String, dynamic>> refreshToken() async {
    final refreshToken = await _getRefreshToken();
    if (refreshToken == null) {
      throw Exception('No refresh token available');
    }

    final response = await _makeRequest(
      ApiConfig.refreshTokenEndpoint,
      _buildHeaders(requiresAuth: false),
      {'refresh_token': refreshToken},
      'POST',
    );

    if (response['success'] == true && response['data'] != null) {
      final newToken = response['data']['token'];
      setAuthToken(newToken);
    }

    return response;
  }

  // Client Portal Methods
  static Future<Map<String, dynamic>> getClientProfile() async {
    return await _makeRequest(
      ApiConfig.clientProfileEndpoint,
      _buildHeaders(),
      null,
      'GET',
    );
  }

  static Future<Map<String, dynamic>> updateClientProfile(Map<String, dynamic> data) async {
    return await _makeRequest(
      ApiConfig.clientProfileEndpoint,
      _buildHeaders(),
      data,
      'PUT',
    );
  }

  static Future<Map<String, dynamic>> getClientCases() async {
    return await _makeRequest(
      ApiConfig.clientCasesEndpoint,
      _buildHeaders(),
      null,
      'GET',
    );
  }

  static Future<Map<String, dynamic>> getClientDocuments() async {
    return await _makeRequest(
      ApiConfig.clientDocumentsEndpoint,
      _buildHeaders(),
      null,
      'GET',
    );
  }

  static Future<Map<String, dynamic>> uploadDocument(
    String filePath,
    String title,
    String description,
    {int? caseId}
  ) async {
    final headers = _buildHeaders();
    headers.remove('Content-Type'); // Let http package set multipart content type
    
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConfig.getEndpoint(ApiConfig.clientDocumentsEndpoint)),
    );
    
    request.headers.addAll(headers);
    request.fields['title'] = title;
    request.fields['description'] = description;
    if (caseId != null) {
      request.fields['case_id'] = caseId.toString();
    }
    
    request.files.add(await http.MultipartFile.fromPath('document', filePath));
    
    try {
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Upload failed: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getClientAppointments() async {
    return await _makeRequest(
      ApiConfig.clientAppointmentsEndpoint,
      _buildHeaders(),
      null,
      'GET',
    );
  }

  static Future<Map<String, dynamic>> createAppointment(Map<String, dynamic> data) async {
    return await _makeRequest(
      ApiConfig.clientAppointmentsEndpoint,
      _buildHeaders(),
      data,
      'POST',
    );
  }

  static Future<Map<String, dynamic>> getClientMessages() async {
    return await _makeRequest(
      ApiConfig.clientMessagesEndpoint,
      _buildHeaders(),
      null,
      'GET',
    );
  }

  static Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> data) async {
    // Check if there are attachments
    final attachments = data['attachments'] as List<String>?;
    
    if (attachments != null && attachments.isNotEmpty) {
      // Send with file attachments using multipart
      final headers = _buildHeaders();
      headers.remove('Content-Type'); // Let http package set multipart content type
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.getEndpoint(ApiConfig.clientMessagesEndpoint)),
      );
      
      request.headers.addAll(headers);
      request.fields['subject'] = data['subject'] ?? '';
      request.fields['message'] = data['message'] ?? '';
      
      // Add file attachments
      for (int i = 0; i < attachments.length; i++) {
        final file = File(attachments[i]);
        if (await file.exists()) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'attachments[]',
              attachments[i],
            ),
          );
        }
      }
      
      try {
        final streamedResponse = await request.send().timeout(_timeout);
        final response = await http.Response.fromStream(streamedResponse);
        
        return _handleResponse(response);
      } catch (e) {
        throw Exception('Message send failed: ${e.toString()}');
      }
    } else {
      // Send without attachments using regular JSON
      return await _makeRequest(
        ApiConfig.clientMessagesEndpoint,
        _buildHeaders(),
        data,
        'POST',
      );
    }
  }

  static Future<Map<String, dynamic>> getClientTasks() async {
    return await _makeRequest(
      ApiConfig.clientTasksEndpoint,
      _buildHeaders(),
      null,
      'GET',
    );
  }

  // Generic methods for backward compatibility
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    return await _makeRequest(endpoint, _buildHeaders(), data, 'POST');
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    return await _makeRequest(endpoint, _buildHeaders(), null, 'GET');
  }

  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    return await _makeRequest(endpoint, _buildHeaders(), data, 'PUT');
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    return await _makeRequest(endpoint, _buildHeaders(), null, 'DELETE');
  }

  // Utility methods
  static Future<String?> _getDeviceToken() async {
    // This would typically get the FCM token
    // For now, return a placeholder
    return 'flutter-device-token';
  }

  static Future<String?> _getRefreshToken() async {
    // Get refresh token from secure storage
    // This would be implemented in AuthService
    return null;
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    return _authToken != null && !_isTokenExpired(_authToken!);
  }

  // Check if token is expired
  static bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final exp = payload['exp'] as int?;
      if (exp == null) return true;

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final threshold = DateTime.now().add(ApiConfig.refreshTokenThreshold);
      
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      return true;
    }
  }

  // Clear authentication data
  static Future<void> clearAuth() async {
    clearAuthToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
  }
}
