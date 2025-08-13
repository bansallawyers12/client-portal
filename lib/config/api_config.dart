class ApiConfig {
  // Base API configuration
  static const String baseUrl = 'https://your-crm-domain.com/api';
  static const String clientPortalEndpoint = '/client-portal';

  // Authentication endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String refreshTokenEndpoint = '/auth/refresh';

  // Client portal specific endpoints
  static const String clientProfileEndpoint = '/client-portal/profile';
  static const String clientCasesEndpoint = '/client-portal/cases';
  static const String clientDocumentsEndpoint = '/client-portal/documents';
  static const String clientAppointmentsEndpoint =
      '/client-portal/appointments';
  static const String clientMessagesEndpoint = '/client-portal/messages';
  static const String clientTasksEndpoint = '/client-portal/tasks';

  // API settings
  static const Duration timeout = Duration(seconds: 30);
  static const Duration refreshTokenThreshold = Duration(minutes: 5);

  // Default headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'Flutter-Client-Portal/1.0.0',
  };

  // Error messages
  static const Map<int, String> errorMessages = {
    400: 'Bad Request - Please check your input',
    401: 'Unauthorized - Please login again',
    403: 'Forbidden - You don\'t have permission',
    404: 'Not Found - Resource not available',
    422: 'Validation Error - Please check your data',
    429: 'Too Many Requests - Please try again later',
    500: 'Server Error - Please try again later',
    502: 'Bad Gateway - Service temporarily unavailable',
    503: 'Service Unavailable - Please try again later',
  };

  // Get full endpoint URL
  static String getEndpoint(String endpoint) {
    if (endpoint.startsWith('http')) {
      return endpoint;
    }
    return '$baseUrl$endpoint';
  }

  // Get client portal endpoint URL
  static String getClientPortalEndpoint(String endpoint) {
    return '$baseUrl$clientPortalEndpoint$endpoint';
  }

  // Get error message for status code
  static String getErrorMessage(int statusCode) {
    return errorMessages[statusCode] ?? 'Unknown error occurred';
  }
}
