import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  static String? authToken;

  // Initialize auth token from SharedPreferences
  static Future<void> initializeAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('auth_token');
  }

  // Login
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'device_name': 'flutter-app',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      authToken = data['token'];

      // Store token in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', authToken!);

      return data;
    } else {
      throw Exception('Login failed');
    }
  }

  // Logout
  static Future<void> logout() async {
    if (authToken == null) return;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Clear token
        authToken = null;
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
      }
    } catch (e) {
      // Even if API call fails, clear local token
      authToken = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    if (authToken == null) {
      await initializeAuthToken();
    }

    final response = await http.get(
      Uri.parse('$baseUrl/client'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile');
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> data,
  ) async {
    if (authToken == null) {
      await initializeAuthToken();
    }

    final response = await http.post(
      Uri.parse('$baseUrl/update_client'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update profile');
    }
  }

  // Get documents
  static Future<List<dynamic>> getDocuments() async {
    if (authToken == null) {
      await initializeAuthToken();
    }

    final response = await http.get(
      Uri.parse('$baseUrl/documents'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load documents');
    }
  }

  // Upload document
  static Future<Map<String, dynamic>> uploadDocument(
    String filePath,
    String title,
    String description,
  ) async {
    if (authToken == null) {
      await initializeAuthToken();
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload_document'),
    );
    request.headers['Authorization'] = 'Bearer $authToken';

    // Add the required form fields
    request.fields['title'] = title;
    request.fields['description'] = description;

    // Add the file
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseData);
    } else {
      throw Exception('Failed to upload document');
    }
  }

  // Get appointments
  static Future<List<dynamic>> getAppointments() async {
    if (authToken == null) {
      await initializeAuthToken();
    }

    final response = await http.get(
      Uri.parse('$baseUrl/appointments'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load appointments');
    }
  }

  // Create appointment
  static Future<Map<String, dynamic>> createAppointment(
    Map<String, dynamic> appointmentData,
  ) async {
    if (authToken == null) {
      await initializeAuthToken();
    }

    final response = await http.post(
      Uri.parse('$baseUrl/appointments'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(appointmentData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create appointment');
    }
  }

  // Get messages
  static Future<List<dynamic>> getMessages() async {
    if (authToken == null) {
      await initializeAuthToken();
    }

    final response = await http.get(
      Uri.parse('$baseUrl/messages'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load messages');
    }
  }

  // Send message
  static Future<Map<String, dynamic>> sendMessage(
    String subject,
    String message,
  ) async {
    if (authToken == null) {
      await initializeAuthToken();
    }

    final response = await http.post(
      Uri.parse('$baseUrl/messages'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'subject': subject, 'message': message}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send message');
    }
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    if (authToken == null) {
      await initializeAuthToken();
    }
    return authToken != null;
  }

  // Clear authentication data
  static Future<void> clearAuth() async {
    authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}
