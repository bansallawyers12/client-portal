import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../utils/app_logger.dart';
import '../utils/cache_helper.dart';
import '../utils/navigation_service.dart';
import 'auth_service.dart';

class ApiService {
  static String? _authToken;
  static const Duration _timeout = Duration(seconds: 30);

  static String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[^a-zA-Z0-9\-_ .\$\(\),&+]'), '_');
  }

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

  static Future<Map<String, dynamic>> register(
    Map<String, dynamic> userData,
  ) async {
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
      AppLogger.error('Logout API call failed: ', e, StackTrace.current);
    } finally {
      clearAuth();
    }

    return {'success': true, 'message': 'Logged out successfully'};
  }

  static Future<void> unregisterFcmToken(String fcmToken) async {
    if (_authToken == null || fcmToken.isEmpty) return;
    try {
      await _makeRequest(ApiConfig.unregisterFCMToken, _buildHeaders(), {
        "token": fcmToken,
      }, 'POST');
    } catch (e) {
      AppLogger.error('FCM unregister failed: ', e, StackTrace.current);
    }
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
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await _makeRequest(
      ApiConfig.resetPasswordEndpoint,
      _buildHeaders(requiresAuth: false),
      {
        'email': email,
        'code': code,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      'POST',
    );
  }

  static Future<Map<String, dynamic>> refreshTokenApi(
    String refreshToken,
  ) async {
    final url = ApiConfig.baseUrl + ApiConfig.refreshTokenEndpoint;

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final body = jsonEncode({'refresh_token': refreshToken.trim()});

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Failed to refresh token: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Register FCM token with the server
  static Future<bool> registerFCMToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final clientId = prefs.getString('user_id');

    if (clientId == null) {
      AppLogger.info('FCM: Missing client ID');
      return false;
    }

    // Store token locally for retry
    await prefs.setString('fcm_token', token);

    try {
      final response = await _makeRequest(
        ApiConfig.registerFCMToken,
        _buildHeaders(requiresAuth: true),
        {'token': token, 'client_id': clientId},
        'POST',
      );

      final success = response['success'] == true;

      await prefs.setBool('fcm_token_registered', success);

      if (success) {
        AppLogger.info('FCM: Token registered successfully');
      } else {
        AppLogger.info(
          'FCM: Failed to register token: ${response['message'] ?? 'Unknown error'}',
        );
      }

      return success;
    } catch (e) {
      await prefs.setBool('fcm_token_registered', false);
      AppLogger.error(
        'FCM: Error registering token: : ',
        e,
        StackTrace.current,
      );
      return false;
    }
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

  static Future<Map<String, dynamic>> updateClientProfile(
    Map<String, dynamic> data,
  ) async {
    return await _makeRequest(
      ApiConfig.clientProfileEndpoint,
      _buildHeaders(),
      data,
      'POST',
    );
  }

  static Future<Map<String, dynamic>> getDashboard({
    required String selMatterId,
  }) async {
    final url = '${ApiConfig.dashboardEndpoint}?sel_matter_id=$selMatterId';
    return await _makeRequest(url, _buildHeaders(), null, 'GET');
  }

  static Future<Map<String, dynamic>> getMatters() async {
    return await _makeRequest(
      ApiConfig.mattersEndpoint,
      _buildHeaders(),
      null,
      'GET',
    );
  }

  static const String _mattersCacheKey = 'matters_v1';

  /// Matters change rarely, so serve a short-lived cache to avoid refetching
  /// on every screen that needs the matter list. Falls back to the network on
  /// a cache miss and refreshes the cache on a successful response.
  static Future<Map<String, dynamic>> getMattersCached({
    bool forceRefresh = false,
    Duration maxAge = const Duration(minutes: 15),
  }) async {
    if (!forceRefresh) {
      final cached = await CacheHelper.loadEnvelope(
        _mattersCacheKey,
        maxAge: maxAge,
      );
      if (cached is Map) return Map<String, dynamic>.from(cached);
    }

    final response = await getMatters();
    if (response['success'] == true && response['data'] != null) {
      await CacheHelper.saveEnvelope(key: _mattersCacheKey, data: response);
    }
    return response;
  }

  // Workflow Methods
  static Future<Map<String, dynamic>> getWorkflowStages({
    int? clientMatterId,
    String type = 'all',
  }) async {
    final endpoint =
        clientMatterId != null
            ? '${ApiConfig.workflowStagesEndpoint}?client_matter_id=$clientMatterId&type=$type'
            : '${ApiConfig.workflowStagesEndpoint}?type=$type';

    return await _makeRequest(endpoint, _buildHeaders(), null, 'GET');
  }

  static Future<Map<String, dynamic>> getWorkflowStageDetails(
    int stageId,
  ) async {
    return await _makeRequest(
      '${ApiConfig.workflowStageDetailsEndpoint}/$stageId',
      _buildHeaders(),
      null,
      'GET',
    );
  }

  static Future<Map<String, dynamic>> getWorkflowAllowedChecklist({
    required int clientMatterId,
    int? stageId,
    int? allowedChecklistID,
  }) async {
    final queryParameters = {
      'client_matter_id': clientMatterId.toString(),
      'stage_id': stageId?.toString() ?? '',
      'allowed_checklist_id': allowedChecklistID?.toString() ?? '',
    };
    final uri = Uri.parse(
      ApiConfig.workflowAllowedChecklistEndpoint,
    ).replace(queryParameters: queryParameters);
    return await _makeRequest(uri.toString(), _buildHeaders(), null, 'GET');
  }

  static Future<Map<String, dynamic>> uploadWorkflowChecklistDocument({
    required Uint8List fileBytes,
    required String fileName,
    required int allowedChecklistId,
    required int clientMatterId,
  }) async {
    final headers = _buildHeaders();
    headers.remove('Content-Type');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        ApiConfig.getEndpoint(ApiConfig.workflowUploadChecklistEndpoint),
      ),
    );

    request.headers.addAll(headers);
    request.fields['client_matter_id'] = clientMatterId.toString();
    request.fields['allowed_checklist_id'] = allowedChecklistId.toString();
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: _sanitizeFileName(fileName),
      ),
    );

    try {
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Upload failed: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> bulkUploadChecklistDocuments({
    required List<({Uint8List bytes, String name})> filesData,
    required List<int> allowedChecklistIds,
    required int clientMatterId,
  }) async {
    final headers = _buildHeaders();
    headers.remove('Content-Type');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        ApiConfig.getEndpoint(
          ApiConfig.workflowUploadAllowedChecklistBulkUpload,
        ),
      ),
    );

    request.headers.addAll(headers);
    request.fields['client_matter_id'] = clientMatterId.toString();
    request.fields['allowed_checklist_ids'] = allowedChecklistIds.join(',');

    for (var fileData in filesData) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'files[]',
          fileData.bytes,
          filename: _sanitizeFileName(fileData.name),
        ),
      );
    }

    try {
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Bulk upload failed: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> getClientCases({
    int page = 1,
    int perPage = 10,
    String search = '',
    String status = '',
    String priority = '',
    String selMatterId = '',
  }) async {
    final endpoint =
        "${ApiConfig.clientCasesEndpoint}?page=$page&per_page=$perPage&search=$search&status=$status&priority=$priority&sel_matter_id=$selMatterId";
    return await _makeRequest(endpoint, _buildHeaders(), null, 'GET');
  }

  static Future<Map<String, dynamic>> getClientDocuments({
    int page = 1,
    int perPage = 10,
    String search = '',
    String status = '',
    String docType = '',
    String selMatterID = '',
  }) async {
    return await _makeRequest(
      "${ApiConfig.clientDocumentsEndpoint}?page=$page&per_page=$perPage&search=$search&status=$status&doc_type=$docType&sel_matter_id=$selMatterID",
      _buildHeaders(),
      null,
      'GET',
    );
  }

  static Future<Map<String, dynamic>> uploadDocument(
    String filePath,
    String title,
    String description, {
    int? caseId,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    final headers = _buildHeaders();
    headers.remove('Content-Type');

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

    if (fileBytes != null && fileName != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'document',
          fileBytes,
          filename: _sanitizeFileName(fileName),
        ),
      );
    } else if (!kIsWeb) {
      request.files.add(
        await http.MultipartFile.fromPath('document', filePath),
      );
    } else {
      throw Exception('File bytes and file name are required on web platform');
    }

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

  static Future<Map<String, dynamic>> createAppointment(
    Map<String, dynamic> data,
  ) async {
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

  static Future<Map<String, dynamic>> sendMessage(
    Map<String, dynamic> data,
  ) async {
    final attachments = data['attachments'] as List<String>?;
    final attachmentsBytes =
        data['attachments_bytes'] as List<({Uint8List bytes, String name})>?;

    final hasAttachments =
        (attachments != null && attachments.isNotEmpty) ||
        (attachmentsBytes != null && attachmentsBytes.isNotEmpty);

    if (hasAttachments) {
      final headers = _buildHeaders();
      headers.remove('Content-Type');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.getEndpoint(ApiConfig.clientMessagesEndpoint)),
      );

      request.headers.addAll(headers);
      request.fields['subject'] = data['subject'] ?? '';
      request.fields['message'] = data['message'] ?? '';

      if (attachmentsBytes != null && attachmentsBytes.isNotEmpty) {
        for (var fileData in attachmentsBytes) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'attachments[]',
              fileData.bytes,
              filename: _sanitizeFileName(fileData.name),
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
      return await _makeRequest(
        ApiConfig.clientMessagesEndpoint,
        _buildHeaders(),
        data,
        'POST',
      );
    }
  }

  /*static Future<Map<String, dynamic>> getClientTasks() async {
    return await _makeRequest(
      ApiConfig.clientTasksEndpoint,
      _buildHeaders(),
      null,
      'GET',
    );
  }*/

  static Future<Map<String, dynamic>> getClientTasks({
    int page = 1,
    int perPage = 10,
    String search = "",
    String status = "all",
    String priority = "all",
  }) async {
    final query =
        "?page=$page&per_page=$perPage&search=$search&status=$status&priority=$priority";

    return await _makeRequest(
      "${ApiConfig.clientTasksEndpoint}$query",
      _buildHeaders(),
      null,
      'GET',
    );
  }

  static Future<Map<String, dynamic>> getRecentActivities({
    int page = 1,
    int perPage = 10,
    String search = "",
  }) async {
    final query = "?page=$page&per_page=$perPage&search=$search&type=";

    return await _makeRequest(
      "${ApiConfig.recentActivityEndpoint}$query",
      _buildHeaders(),
      null,
      'GET',
    );
  }

  static Future<Map<String, dynamic>> getDocumentCategories({
    String type = "personal",
  }) async {
    return await _makeRequest(
      "${ApiConfig.documentsEndpoint}/$type/categories",
      _buildHeaders(),
      null,
      'GET',
    );
  }

  static Future<List<dynamic>> getDocumentChecklist({
    String type = "personal",
  }) async {
    final response = await _makeRequest(
      "${ApiConfig.documentsEndpoint}/$type/checklist",
      _buildHeaders(),
      null,
      'GET',
    );

    return response['data']['checklist'] ?? [];
  }

  static Future<Map<String, dynamic>> getChatRecipients() async {
    return await _makeRequest(
      ApiConfig.messagesRecipients,
      _buildHeaders(),
      null,
      'GET',
    );
  }

  static Future<Map<String, dynamic>> getWorkflowMessages({
    required int clientMatterId,
    int page = 1,
    int limit = 20,
  }) async {
    final url = Uri.parse(ApiConfig.messagesList).replace(
      queryParameters: {
        'client_matter_id': clientMatterId.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    return await _makeRequest(url.toString(), _buildHeaders(), null, 'GET');
  }

  static Future<Map<String, dynamic>> getMessageDetail(int messageId) async {
    return await _makeRequest(
      '${ApiConfig.messagesList}/$messageId',
      _buildHeaders(),
      null,
      'GET',
    );
  }

  static Future<Map<String, dynamic>> sendChatMessage({
    required int clientMatterId,
    required String message,
  }) async {
    final body = {
      'client_matter_id': clientMatterId.toString(),
      'message': message,
    };

    return await _makeRequest(
      ApiConfig.messagesSend,
      _buildHeaders(),
      body,
      'POST',
    );
  }

  static Future<Map<String, dynamic>> checkUserAuthentication() async {
    return await _makeRequest(
      ApiConfig.checkUserAuthentication,
      _buildHeaders(),
      null,
      'GET',
    );
  }

  static Future<Map<String, dynamic>> sendChatMessageWithAttachments({
    required int clientMatterId,
    required String message,
    List<({Uint8List bytes, String name})>? attachmentBytes,
  }) async {
    try {
      var uri = Uri.parse(ApiConfig.getEndpoint(ApiConfig.messagesSend));
      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll(_buildHeaders());

      request.fields['client_matter_id'] = clientMatterId.toString();
      request.fields['message'] = message;

      if (attachmentBytes != null && attachmentBytes.isNotEmpty) {
        for (var fileData in attachmentBytes) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'attachments[]',
              fileData.bytes,
              filename: _sanitizeFileName(fileData.name),
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to send message: ${response.statusCode} ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      throw Exception('Error sending message with attachments: $e');
    }
  }

  static Future<Map<String, dynamic>> markMessageAsRead({
    required int messageId,
  }) async {
    final url = '${ApiConfig.messageRead}/$messageId/read';
    final headers = _buildHeaders();
    final body = {};
    return await _makeRequest(url, headers, body, 'POST');
  }

  static Future<Map<String, dynamic>> getUnreadMessageCount({
    required int clientMatterId,
  }) async {
    final params = {'client_matter_id': clientMatterId.toString()};

    return await _makeRequest(
      ApiConfig.messageUnreadCount,
      _buildHeaders(),
      params,
      'GET',
    );
  }

  static Future<Map<String, dynamic>> getClientPersonalDetail({
    String tab = 'all',
  }) async {
    String endpoint = '${ApiConfig.getClientPersonalDetailEndpoint}?tab=$tab';

    return await _makeRequest(endpoint, _buildHeaders(), null, 'GET');
  }

  static Future<Map<String, dynamic>> getCountries() async {
    String endpoint = '${ApiConfig.baseUrl}/countries';

    return await _makeRequest(endpoint, _buildHeaders(), null, 'GET');
  }

  static Future<Map<String, dynamic>> getVisaTypes() async {
    String endpoint = "${ApiConfig.baseUrl}/visa-types";

    return await _makeRequest(endpoint, _buildHeaders(), null, "GET");
  }

  static Future<Map<String, dynamic>> deleteClientTabDetail({
    required int id,
    required String type,
  }) async {
    String endpoint = "${ApiConfig.baseUrl}/delete-client-tab-detail";
    final params = {"id": id, "type": type};
    return await _makeRequest(endpoint, _buildHeaders(), params, 'POST');
  }

  static Future<Map<String, dynamic>> updateClientBasicDetail({
    required String firstName,
    required String lastName,
    required String dob,
    required String gender,
    required String maritalStatus,
  }) async {
    const endpoint = ApiConfig.updateClientBasicDetail;

    final response = await _makeRequest(endpoint, _buildHeaders(), {
      "first_name": firstName,
      "last_name": lastName,
      "date_of_birth": dob,
      "gender": gender,
      "marital_status": maritalStatus,
    }, "POST");
    AppLogger.info("UPDATE RESPONSE: $response");
    return response;
  }

  static Future<Map<String, dynamic>> updateClientPhoneDetail(
    List<Map<String, dynamic>> phones,
  ) async {
    const endpoint = ApiConfig.updateClientPhoneDetail;

    final response = await _makeRequest(endpoint, _buildHeaders(), {
      "phones": phones,
    }, "POST");

    AppLogger.info("UPDATE PHONE RESPONSE: $response");
    return response;
  }

  static Future<Map<String, dynamic>> updateClientEmailDetail(
    List<Map<String, dynamic>> emails,
  ) async {
    const endpoint = ApiConfig.updateClientEmailDetail;

    final response = await _makeRequest(endpoint, _buildHeaders(), {
      "emails": emails,
    }, "POST");
    return response;
  }

  static Future<Map<String, dynamic>> updateClientPassportDetail(
    List<Map<String, dynamic>> passports,
  ) async {
    const endpoint = ApiConfig.updateClientPassportDetail;

    final response = await _makeRequest(endpoint, _buildHeaders(), {
      "passports": passports,
    }, "POST");

    return response;
  }

  static Future<Map<String, dynamic>> updateClientVisaDetail(
    List<Map<String, dynamic>> visas,
  ) async {
    const endpoint = ApiConfig.updateClientVisaDetail;

    final response = await _makeRequest(endpoint, _buildHeaders(), {
      "visas": visas,
    }, "POST");

    return response;
  }

  static Future<Map<String, dynamic>> updateClientAddressDetail(
    List<Map<String, dynamic>> addresses,
  ) async {
    final response = await _makeRequest(
      ApiConfig.updateClientAddressDetail,
      _buildHeaders(),
      {"addresses": addresses},
      "POST",
    );

    return response;
  }

  static Future<Map<String, dynamic>> updateClientTravelDetail(
    List<Map<String, dynamic>> travels,
  ) async {
    const endpoint = ApiConfig.updateClientTravelDetail;

    final response = await _makeRequest(endpoint, _buildHeaders(), {
      "travels": travels,
    }, "POST");

    return response;
  }

  static Future<Map<String, dynamic>> updateClientQualificationDetail(
    List<Map<String, dynamic>> qualifications,
  ) async {
    const endpoint = ApiConfig.updateClientQualificationDetail;

    final response = await _makeRequest(endpoint, _buildHeaders(), {
      "qualifications": qualifications,
    }, "POST");

    return response;
  }

  static Future<Map<String, dynamic>> updateClientExperienceDetail(
    List<Map<String, dynamic>> experiences,
  ) async {
    const endpoint = ApiConfig.updateClientExperienceDetail;

    final response = await _makeRequest(endpoint, _buildHeaders(), {
      "experiences": experiences,
    }, "POST");

    return response;
  }

  static Future<Map<String, dynamic>> updateClientOccupationDetail(
    List<Map<String, dynamic>> occupations,
  ) async {
    const endpoint = ApiConfig.updateClientOccupationDetail;

    final response = await _makeRequest(endpoint, _buildHeaders(), {
      "occupations": occupations,
    }, "POST");

    return response;
  }

  static Future<Map<String, dynamic>> updateClientTestScoreDetail(
    List<Map<String, dynamic>> testScores,
  ) async {
    const endpoint = ApiConfig.updateClientTestScoreDetail;

    final response = await _makeRequest(endpoint, _buildHeaders(), {
      "test_scores": testScores,
    }, "POST");

    return response;
  }

  static Future<Map<String, dynamic>> getAppointmentVariableLists() async {
    const endpoint = ApiConfig.appointmentVariableLists;

    final response = await _makeRequest(endpoint, _buildHeaders(), null, "GET");

    return response;
  }

  static Future<Map<String, dynamic>> getAppointments({
    int page = 1,
    int perPage = 50,
  }) async {
    final endpoint = "${ApiConfig.appointments}?per_page=$perPage&page=$page";

    final response = await _makeRequest(endpoint, _buildHeaders(), null, "GET");
    return response;
  }

  static Future<Map<String, dynamic>> getAppointmentById(int id) async {
    final endpoint = "${ApiConfig.appointments}/$id";
    final response = await _makeRequest(endpoint, _buildHeaders(), null, "GET");
    return response;
  }

  static Future<Map<String, dynamic>> getAppointmentPaymentHistory(
    int id,
  ) async {
    final endpoint = "${ApiConfig.appointments}/$id/payment-history";
    final response = await _makeRequest(endpoint, _buildHeaders(), null, "GET");
    return response;
  }

  static Future<Map<String, dynamic>> cancelAppointment({
    required int id,
    required String reason,
  }) async {
    final endpoint = "${ApiConfig.appointments}/$id/status";

    final body = {"type": "cancel", "cancel_reason": reason};

    final response = await _makeRequest(
      endpoint,
      _buildHeaders(),
      body,
      "POST",
    );
    return response;
  }

  static Future<Map<String, dynamic>> updateAppointment({
    required int appointmentId,
    required String appointmentDate,
    required String appointmentTime,
    required int meetingType,
    required int preferredLanguage,
  }) async {
    final endpoint = ApiConfig.appointmentsUpdate;

    final body = {
      "appointment_id": appointmentId,
      "appointment_date": appointmentDate,
      "appointment_time": appointmentTime,
      "meeting_type": meetingType,
      "preferred_language": preferredLanguage,
    };

    final response = await _makeRequest(
      endpoint,
      _buildHeaders(),
      body,
      "POST",
    );
    return response;
  }

  static Future<Map<String, dynamic>> getDisabledDates({
    required String id,
    required String enquiryItem,
    required String inPersonAddress,
  }) async {
    const endpoint = ApiConfig.appointmentsGetDisabledDates;

    final response = await _makeRequest(endpoint, _buildHeaders(), {
      "id": id,
      "enquiry_item": enquiryItem,
      "inperson_address": inPersonAddress,
    }, "POST");

    return response;
  }

  static Future<Map<String, dynamic>> getDisabledSlots({
    required String serviceId,
    required String enquiryItem,
    required String inPersonAddress,
    required String selectedDate,
  }) async {
    const endpoint = ApiConfig.appointmentsGetDisabledSlots;

    final response = await _makeRequest(endpoint, _buildHeaders(), {
      "service_id": serviceId,
      "enquiry_item": enquiryItem,
      "inperson_address": inPersonAddress,
      "sel_date": selectedDate,
    }, "POST");

    return response;
  }

  static Future<Map<String, dynamic>> createAppointmentNew({
    required int noeId,
    required int serviceId,
    required String appointDate,
    required String appointTime,
    required String description,
    required String appointmentDetails,
    required String preferredLanguage,
    required int inPersonAddress,
  }) async {
    const endpoint = ApiConfig.appointments;

    final response = await _makeRequest(endpoint, _buildHeaders(), {
      "noe_id": noeId,
      "service_id": serviceId,
      "appoint_date": appointDate,
      "appoint_time": appointTime,
      "description": description,
      "appointment_details": appointmentDetails,
      "preferred_language": preferredLanguage,
      "inperson_address": inPersonAddress,
    }, "POST");
    return response;
  }

  static Future<Map<String, dynamic>> createAppointmentWithoutLogin({
    required int noeId,
    required int serviceId,
    required String appointDate,
    required String appointTime,
    required String description,
    required int appointmentDetails,
    required int preferredLanguage,
    required int inPersonAddress,
    required String fullName,
    required String email,
    required String phone,
    required String countryCode,
  }) async {
    const endpoint = ApiConfig.appointmentsWithoutLogin;

    final response = await _makeRequest(
      endpoint,
      {"Accept": "application/json", "Content-Type": "application/json"},
      {
        "noe_id": noeId,
        "service_id": serviceId,
        "appoint_date": appointDate,
        "appoint_time": appointTime,
        "description": description,
        "appointment_details": appointmentDetails,
        "preferred_language": preferredLanguage,
        "inperson_address": inPersonAddress,
        "full_name": fullName,
        "email": email,
        "phone": phone,
        "country_code": countryCode,
      },
      "POST",
    );

    return response;
  }

  static Future<Map<String, dynamic>> processAppointmentPayment({
    required int appointmentId,
    required double amount,
    required String paymentMethodId,
    required String currency,
  }) async {
    final endpoint = ApiConfig.appointmentsProcessPayment;
    final response = await _makeRequest(endpoint, _buildHeaders(), {
      'appointment_id': appointmentId,
      'amount': amount,
      'payment_method_id': paymentMethodId,
      'currency': currency,
    }, "POST");
    return response;
  }

  static Future<Map<String, dynamic>> recordAppointmentPayment({
    required int appointmentId,
    required String paymentIntentId,
  }) async {
    final endpoint = ApiConfig.appointmentsRecordPayment;

    final response = await _makeRequest(endpoint, _buildHeaders(), {
      'appointment_id': appointmentId,
      'payment_intent_id': paymentIntentId,
    }, "POST");

    return response;
  }

  static Future<Map<String, dynamic>> recordAppointmentPaymentWithoutLogin({
    required int appointmentId,
    required String paymentIntentId,
  }) async {
    final endpoint = ApiConfig.appointmentsRecordPaymentWithLogin;

    final response = await _makeRequest(endpoint, _buildHeaders(), {
      'appointment_id': appointmentId,
      'payment_intent_id': paymentIntentId,
    }, "POST");

    return response;
  }

  static Future<Map<String, dynamic>> recordPaymentWallet({
    required int appointmentId,
    required String paymentIntentId,
    required String paymentType,
  }) async {
    final endpoint = ApiConfig.appointmentsRecordPaymentWallet;

    final response = await _makeRequest(endpoint, _buildHeaders(), {
      'appointment_id': appointmentId,
      'payment_intent_id': paymentIntentId,
      'payment_type': paymentType,
    }, "POST");

    return response;
  }

  static Future<Map<String, dynamic>> recordPaymentWalletWithoutLogin({
    required int appointmentId,
    required String paymentIntentId,
    required String paymentType,
  }) async {
    final endpoint = ApiConfig.appointmentsRecordPaymentWalletWithoutLogin;

    final response = await _makeRequest(endpoint, _buildHeaders(), {
      'appointment_id': appointmentId,
      'payment_intent_id': paymentIntentId,
      'payment_type': paymentType,
    }, "POST");

    return response;
  }

  static Future<Map<String, dynamic>> getNotifications({
    required int clientMatterId,
    int page = 1,
    int limit = 20,
  }) async {
    //final url = '${ApiConfig.notifications}?client_matter_id=$clientMatterId&page=$page&limit=$limit';
    final url = '${ApiConfig.notifications}?page=$page&limit=$limit';
    return await _makeRequest(url, _buildHeaders(), null, 'GET');
  }

  static Future<Map<String, dynamic>> getRecentUnreadNotifications() async {
    final url = ApiConfig.notificationsRecentUnread;
    return await _makeRequest(url, _buildHeaders(), null, 'GET');
  }

  static Future<Map<String, dynamic>> getUnreadNotificationCount() async {
    final url = ApiConfig.notificationsUnreadCount;
    return await _makeRequest(url, _buildHeaders(), null, 'GET');
  }

  static Future<Map<String, dynamic>> getNotificationDetail({
    required int notificationId,
  }) async {
    final url = '${ApiConfig.notifications}/$notificationId';

    return await _makeRequest(url, _buildHeaders(), null, 'GET');
  }

  static Future<bool> markNotificationAsRead({
    required int notificationId,
  }) async {
    final url = '${ApiConfig.notifications}/$notificationId/read';

    final response = await _makeRequest(url, _buildHeaders(), null, 'POST');
    return response['success'] ?? false;
  }

  static Future<Map<String, dynamic>> getInvoices({
    required int clientMatterId,
    int page = 1,
    int perPage = 10,
  }) async {
    final url =
        '${ApiConfig.billingList}?client_matter_id=$clientMatterId&page=$page&per_page=$perPage';

    return await _makeRequest(url, _buildHeaders(), null, 'GET');
  }

  static Future<Map<String, dynamic>> updateInvoicePayment({
    required int billingInvoiceId,
    required int clientMatterId,
    required String paymentType,
    required String paymentToken,
    required String paymentStatus,
  }) async {
    final url = ApiConfig.billingInvoiceUpdate;

    final body = {
      "billing_invoice_id": billingInvoiceId,
      "client_matter_id": clientMatterId,
      "payment_type": paymentType,
      "payment_token": paymentToken,
      "payment_status": paymentStatus,
    };

    return await _makeRequest(url, _buildHeaders(), body, 'POST');
  }

  /*static Future<Map<String, dynamic>> getVisaList() async {
    final url = ApiConfig.visaEstimateVisaList;

    return await _makeRequest(url, _buildHeaders(), null, 'GET');
  }*/

  static Future<dynamic> getVisaList({int limit = 160}) async {
    final url = ApiConfig.visaEstimateVisaList;
    return await ApiService.get("$url?limit=$limit");
  }

  static Future<Map<String, dynamic>> getVisaEstimate({
    required String visaId,
    int additional18Plus = 0,
    int additionalU18 = 0,
  }) async {
    final url = ApiConfig.visaEstimateEstimate;

    final body = {
      "visa_id": visaId,
      "additional_applicants_18_plus": additional18Plus,
      "additional_applicants_u18": additionalU18,
    };

    return await _makeRequest(url, _buildHeaders(), body, 'POST');
  }

  static Future<Map<String, dynamic>> getActionRequired() async {
    final url = ApiConfig.actionRequired;
    return await _makeRequest(url, _buildHeaders(), null, 'GET');
  }

  static Future<Map<String, dynamic>> getActionRequiredList({
    int page = 1,
    int limit = 20,
  }) async {
    final url = '${ApiConfig.actionRequired}?page=$page&limit=$limit';
    return await _makeRequest(url, _buildHeaders(), null, 'GET');
  }

  static Future<Map<String, dynamic>> sendChatBotMessage(String message) async {
    final url = ApiConfig.chatBot;
    final body = {"message": message};
    return await _makeRequest(url, _buildHeaders(), body, 'POST');
  }

  // Generic methods for backward compatibility
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    return await _makeRequest(endpoint, _buildHeaders(), data, 'POST');
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    return await _makeRequest(endpoint, _buildHeaders(), null, 'GET');
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
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

      return threshold.isAfter(expiryDate);
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
