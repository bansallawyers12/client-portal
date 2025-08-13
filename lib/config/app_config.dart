class AppConfig {
  // App Information
  static const String appName = 'LegiComply Client Portal';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Immigration & Legal Services Client Portal';
  
  // Company Information
  static const String companyName = 'LegiComply';
  static const String companyWebsite = 'https://legicomply.com';
  static const String supportEmail = 'support@legicomply.com';
  static const String supportPhone = '+1-800-LEGI-HELP';
  
  // API Configuration
  static const String apiBaseUrl = 'https://your-crm-domain.com/api';
  static const String clientPortalEndpoint = '/client-portal';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // File Upload Configuration
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedFileTypes = [
    'pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'gif'
  ];
  
  // App Settings
  static const int sessionTimeoutMinutes = 60;
  static const int maxRetryAttempts = 3;
  static const Duration cacheExpiry = Duration(hours: 24);
  
  // Feature Flags
  static const bool enableBiometricAuth = true;
  static const bool enableOfflineMode = true;
  static const bool enablePushNotifications = true;
  static const bool enableRealTimeChat = true;
  
  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  // Notification Configuration
  static const int maxNotifications = 100;
  static const Duration notificationTimeout = Duration(seconds: 5);
  
  // Security Configuration
  static const int minPasswordLength = 8;
  static const bool requireSpecialCharacters = true;
  static const bool requireNumbers = true;
  static const bool requireUppercase = true;
  
  // Offline Configuration
  static const int maxOfflineActions = 50;
  static const Duration syncInterval = Duration(minutes: 15);
  
  // Analytics Configuration
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enablePerformanceMonitoring = true;
}
