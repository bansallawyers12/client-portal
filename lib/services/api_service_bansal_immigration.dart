import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../config/api_config_bansal_immigration.dart';
import '../utils/navigation_service.dart';
import 'auth_service.dart';

class ApiServiceBansalImmigration{

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
      final uri = Uri.parse(getEndpoint(endpoint));

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

      if (response.statusCode == 401) {
        final refreshed = await _handleTokenRefresh();

        if (refreshed) {
          final newHeaders = _buildHeaders();
          return _makeRequest(endpoint, newHeaders, body, method);
        } else {
          await AuthService.logout(false);
          navigatorKey.currentState?.pushNamedAndRemoveUntil(
            '/login',
                (route) => false,
          );
        }
      }
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

  static bool _isRefreshing = false;
  static Future<bool>? _refreshFuture;

  static Future<bool> _handleTokenRefresh() async {
    if (_isRefreshing) {
      return await _refreshFuture!;
    }

    _isRefreshing = true;
    _refreshFuture = AuthService.refreshToken();

    final success = await _refreshFuture!;
    _isRefreshing = false;

    return success;
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
  static Future<Map<String, dynamic>> login(
      String email,
      String password,
      ) async {
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

  static String getEndpoint(String endpoint) {
    if (endpoint.startsWith('http')) {
      return endpoint;
    }
    final baseUrl = ApiConfigBansalImmigration.baseUrl;
    return '$baseUrl$endpoint';
  }

  static Future<String?> _getDeviceToken() async {
    // This would typically get the FCM token
    // For now, return a placeholder
    return 'flutter-device-token';
  }

  // Blog Methods (public — no auth required)
  static Future<Map<String, dynamic>> getBlogs({
    int page = 1,
    int perPage = 10,
  }) async {
    final endpoint =
        '${ApiConfigBansalImmigration.blogListEndpoint}?page=$page&per_page=$perPage';
    return await _makeRequest(
      endpoint,
      _buildHeaders(requiresAuth: false),
      null,
      'GET',
    );
  }

  static Future<Map<String, dynamic>> getBlogDetail({
    required int blogId,
  }) async {
    final endpoint =
        '${ApiConfigBansalImmigration.blogDetailEndpoint}/$blogId';
    return await _makeRequest(
      endpoint,
      _buildHeaders(requiresAuth: false),
      null,
      'GET',
    );
  }

  // PR Point Calculator Methods
  static Future<Map<String, dynamic>> getPRPoints() async {
    return await _makeRequest(
      ApiConfigBansalImmigration.prPointsCalcList,
      _buildHeaders(requiresAuth: false),
      null,
      'GET',
    );
  }

  static Future<Map<String, dynamic>> calculatePRPoints({
    required Map<String, dynamic> payload,
  }) async {
    return await _makeRequest(
      ApiConfigBansalImmigration.prPointCalcResult,
      _buildHeaders(requiresAuth: false),
      payload,
      'POST',
    );
  }

  // Student Fund Calculator Methods
  static Future<Map<String, dynamic>> getStudentCalcLists() async {
    return await _makeRequest(
      ApiConfigBansalImmigration.studentCalcList,
      _buildHeaders(requiresAuth: false),
      null,
      'GET',
    );
  }

  static Future<Map<String, dynamic>> calculateStudentFund({
    required Map<String, dynamic> payload,
  }) async {
    return await _makeRequest(
      ApiConfigBansalImmigration.studentCalcResult,
      _buildHeaders(requiresAuth: false),
      payload,
      'POST',
    );
  }

  // Postcode Checker Methods
  static Future<Map<String, dynamic>> postcodeAll() async {
    return await _makeRequest(
      ApiConfigBansalImmigration.postCodeAll,
      _buildHeaders(requiresAuth: false),
      null,
      'GET',
    );
  }

  static Future<Map<String, dynamic>> postcodeSearch(String query) async {
    final endpoint = '${ApiConfigBansalImmigration.postCodeSearch}?q=$query';
    return await _makeRequest(endpoint, _buildHeaders(requiresAuth: false), null, 'GET');
  }

  static Future<Map<String, dynamic>> postcodeResult(String postcode) async {
    final endpoint = '${ApiConfigBansalImmigration.postCodeResult}?postcode=$postcode';
    return await _makeRequest(endpoint, _buildHeaders(requiresAuth: false), null, 'GET');
  }

  // Occupation Methods
  static Future<Map<String, dynamic>> getAllOccupations() async {
    return await _makeRequest(
      ApiConfigBansalImmigration.occupationAll,
      _buildHeaders(requiresAuth: false),
      null,
      'GET',
    );
  }

  static Future<Map<String, dynamic>> searchOccupation(String query) async {
    final endpoint = '${ApiConfigBansalImmigration.searchOccupation}?q=$query&limit=20&page=1';
    return await _makeRequest(endpoint, _buildHeaders(requiresAuth: false), null, 'GET');
  }

  static Future<Map<String, dynamic>> getOccupationDetails(String code) async {
    final endpoint = '${ApiConfigBansalImmigration.occupationResult}?occupation_code=$code';
    return await _makeRequest(endpoint, _buildHeaders(requiresAuth: false), null, 'GET');
  }
}