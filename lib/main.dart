import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/user_nav.dart';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'fcm_service.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.light,
);

// Tailwind-mapped colors (light)
const Color kBackgroundLight = Color(0xFFF0F4F8); // hsl(213, 27%, 95%)
const Color kForegroundLight = Color(0xFF30475E); // hsl(211, 33%, 28%)
const Color kCardLight = Color(0xFFFFFFFF); // hsl(0, 0%, 100%)
const Color kPrimaryLight = Color(0xFF5E8B7E); // hsl(163, 19%, 46%)
const Color kSecondaryLight = Color(0xFFF5F8FA); // hsl(210, 40%, 96.1%)
const Color kBorderLight = Color(0xFFE3E8EF); // hsl(214.3, 31.8%, 91.4%)
const Color kSidebarBackgroundLight = Color(0xFFF0F4F8); // hsl(213, 27%, 95%)

// Tailwind-mapped colors (dark)
const Color kBackgroundDark = Color(0xFF181C2A); // hsl(222, 47%, 11%)
const Color kForegroundDark = Color(0xFFE5EAF2); // hsl(210, 40%, 98%)
const Color kCardDark = Color(0xFF1B2030); // hsl(222, 47%, 11.5%)
const Color kPrimaryDark = Color(0xFF5E8B7E); // hsl(163, 19%, 46%)
const Color kSecondaryDark = Color(0xFF23273A); // hsl(217.2, 32.6%, 17.5%)
const Color kBorderDark = Color(0xFF2C3142); // hsl(217.2, 32.6%, 22.5%)
const Color kSidebarBackgroundDark = Color(0xFF181C2A); // hsl(222, 47%, 11%)

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: kPrimaryLight,
  scaffoldBackgroundColor: kBackgroundLight,
  cardColor: kCardLight,
  colorScheme: ColorScheme.light(
    primary: kPrimaryLight,
    secondary: kSecondaryLight,
    surface: kCardLight,
    onPrimary: kForegroundLight,
    onSecondary: kForegroundLight,
    onSurface: kForegroundLight,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: kSidebarBackgroundLight,
    foregroundColor: kForegroundLight,
    elevation: 0,
  ),
  dividerColor: kBorderLight,
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: kSidebarBackgroundLight,
    selectedItemColor: kPrimaryLight,
    unselectedItemColor: kBorderLight,
  ),
  textTheme: GoogleFonts.interTextTheme().copyWith(
    headlineLarge: GoogleFonts.spaceGrotesk(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: kForegroundLight,
    ),
    headlineMedium: GoogleFonts.spaceGrotesk(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: kForegroundLight,
    ),
    headlineSmall: GoogleFonts.spaceGrotesk(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: kForegroundLight,
    ),
    bodyLarge: GoogleFonts.inter(fontSize: 16, color: kForegroundLight),
    bodyMedium: GoogleFonts.inter(fontSize: 14, color: kForegroundLight),
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: kPrimaryDark,
  scaffoldBackgroundColor: kBackgroundDark,
  cardColor: kCardDark,
  colorScheme: ColorScheme.dark(
    primary: kPrimaryDark,
    secondary: kSecondaryDark,
    surface: kCardDark,
    onPrimary: kForegroundDark,
    onSecondary: kForegroundDark,
    onSurface: kForegroundDark,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: kSidebarBackgroundDark,
    foregroundColor: kForegroundDark,
    elevation: 0,
  ),
  dividerColor: kBorderDark,
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: kSidebarBackgroundDark,
    selectedItemColor: kPrimaryDark,
    unselectedItemColor: kBorderDark,
  ),
  textTheme: GoogleFonts.interTextTheme().copyWith(
    headlineLarge: GoogleFonts.spaceGrotesk(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: kForegroundDark,
    ),
    headlineMedium: GoogleFonts.spaceGrotesk(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: kForegroundDark,
    ),
    headlineSmall: GoogleFonts.spaceGrotesk(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: kForegroundDark,
    ),
    bodyLarge: GoogleFonts.inter(fontSize: 16, color: kForegroundDark),
    bodyMedium: GoogleFonts.inter(fontSize: 14, color: kForegroundDark),
  ),
);

// Firebase Messaging background handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');

  // You can add custom logic here for background message handling
  // For example, updating local storage, showing local notifications, etc.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize services
  await AuthService.initialize();
  await ApiService.initializeAuthToken();

  // Initialize FCM service
  final fcmService = FCMService();
  await fcmService.initialize();

  // Handle notification taps when app is opened from notification
  fcmService.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      debugPrint('App opened from notification: ${message.messageId}');
      // You can add navigation logic here based on the notification data
    }
  });

  runApp(MyAppWithTheme());
}

class MyAppWithTheme extends StatelessWidget {
  const MyAppWithTheme({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Client Portal',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: mode,
          initialRoute: '/',
          routes: {
            '/': (context) => const AuthWrapper(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/dashboard': (context) => const DashboardScreen(),
          },
        );
      },
    );
  }
}

// Auth wrapper to check authentication status
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAuthStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return const DashboardScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }

  Future<bool> _checkAuthStatus() async {
    // Add a small delay to ensure AuthService is initialized
    await Future.delayed(Duration(milliseconds: 100));
    return AuthService.isAuthenticated;
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (!Platform.isWindows) {
      _setupNotifications();
    }
  }

  Future<void> _setupNotifications() async {
    final fcmService = FCMService();

    // Set up message listeners
    fcmService.setupMessageListeners(
      onForegroundMessage: (RemoteMessage message) {
        if (!mounted) return;
        debugPrint('Got a message whilst in the foreground!');
        if (message.notification != null) {
          // Show in-app notification or update UI
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message.notification!.body ?? 'New notification'),
              backgroundColor: Color(0xFF5E8B7E),
              duration: Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      },
      onBackgroundMessageTap: (RemoteMessage message) {
        debugPrint(
          'Notification tapped while app in background: ${message.messageId}',
        );
        // You can add navigation logic here based on the notification data
        // For example, navigate to a specific page based on the notification type
      },
    );

    // Get the FCM token and register it
    String? token = await fcmService.getToken();
    if (token != null) {
      await fcmService.registerToken(token);
    }
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await ApiService.login(
        _emailController.text,
        _passwordController.text,
      );

      // Get user profile
      if (data['user'] != null) {
        final prefs = await SharedPreferences.getInstance();
        final userData = data['user'];
        await prefs.setString('user_id', userData['id'].toString());
        await prefs.setString('user_first_name', userData['first_name'] ?? '');
        await prefs.setString('user_last_name', userData['last_name'] ?? '');
        await prefs.setString('user_email', userData['email'] ?? '');
        await prefs.setString('client_id', userData['client_id'] ?? '');
        await prefs.setBool('is_admin', userData['is_admin'] ?? false);

        // Store additional user fields if they exist
        if (userData['gender'] != null) {
          await prefs.setString('user_gender', userData['gender']);
        }
        if (userData['age'] != null) {
          await prefs.setString('user_age', userData['age']);
        }
        if (userData['marital_status'] != null) {
          await prefs.setString(
            'user_marital_status',
            userData['marital_status'],
          );
        }
        if (userData['phone_number1'] != null) {
          await prefs.setString('user_phone1', userData['phone_number1']);
        }
        if (userData['phone_number2'] != null) {
          await prefs.setString('user_phone2', userData['phone_number2']);
        }
        if (userData['phone_number3'] != null) {
          await prefs.setString('user_phone3', userData['phone_number3']);
        }
        if (userData['address'] != null) {
          await prefs.setString('user_address', userData['address']);
        }
        if (userData['city'] != null) {
          await prefs.setString('user_city', userData['city']);
        }
        if (userData['state'] != null) {
          await prefs.setString('user_state', userData['state']);
        }
        if (userData['post_code'] != null) {
          await prefs.setString('user_post_code', userData['post_code']);
        }
        if (userData['country'] != null) {
          await prefs.setString('user_country', userData['country']);
        }
      }

      // Register FCM token after successful login
      if (!Platform.isWindows) {
        final fcmService = FCMService();
        String? fcmToken = await fcmService.getToken();
        if (fcmToken != null) {
          await fcmService.registerToken(fcmToken);
        }
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Direct login method for testing purposes
  Future<void> _directLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate a delay to show loading state
      await Future.delayed(Duration(milliseconds: 500));

      // Store mock user data for testing
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', '1');
      await prefs.setString('user_first_name', 'Test');
      await prefs.setString('user_last_name', 'User');
      await prefs.setString('user_email', 'test@example.com');
      await prefs.setString('client_id', 'TEST123456');
      await prefs.setBool('is_admin', false);
      await prefs.setString('user_gender', 'Male');
      await prefs.setString('user_age', '30');
      await prefs.setString('user_marital_status', 'Single');
      await prefs.setString('user_phone1', '+1234567890');
      await prefs.setString('user_phone2', '+0987654321');
      await prefs.setString('user_phone3', '');
      await prefs.setString('user_address', '123 Test Street');
      await prefs.setString('user_city', 'Test City');
      await prefs.setString('user_state', 'Test State');
      await prefs.setString('user_post_code', '12345');
      await prefs.setString('user_country', 'Test Country');
      await prefs.setString('contact_type1', 'Personal');
      await prefs.setString('contact_type2', 'Secondary');
      await prefs.setString('contact_type3', 'Not In Use');
      await prefs.setString('email_type', 'Personal');
      await prefs.setString('email2', 'secondary@example.com');
      await prefs.setBool('phone_verify', true);
      await prefs.setBool('email_verify', true);
      await prefs.setString('visa_type', 'Student Visa');
      await prefs.setString('visa_expiry', '2025-12-31');
      await prefs.setString('preferred_intake', 'February 2024');
      await prefs.setString('passport_country', 'Test Country');
      await prefs.setString('passport_number', 'TEST123456');
      await prefs.setString('nominated_occupation', 'Software Developer');
      await prefs.setString('skill_assessment', 'Yes');
      await prefs.setString('highest_qualification_aus', 'Bachelor Degree');
      await prefs.setString('highest_qualification_overseas', 'Master Degree');
      await prefs.setString('work_exp_aus', '2 years');
      await prefs.setString('work_exp_overseas', '5 years');
      await prefs.setString('english_score', '7.5');
      await prefs.setString('theme_mode', 'light');

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Direct login failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'LegiComply Client Portal',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 32),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Login'),
                ),
              ),
              SizedBox(height: 16),
              // Direct login button for testing
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _directLogin,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Color(
                      0xFFF39C12,
                    ), // Orange color to distinguish from main login
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('Direct Login (Testing)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardScaffold extends StatefulWidget {
  const DashboardScaffold({super.key});

  @override
  State<DashboardScaffold> createState() => _DashboardScaffoldState();
}

class _DashboardScaffoldState extends State<DashboardScaffold> {
  int _selectedIndex = 0;
  bool _sidebarCollapsed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<_SidebarNavItem> _navItems = [
    _SidebarNavItem('Dashboard', Icons.dashboard),
    _SidebarNavItem('Profile', Icons.person),
    _SidebarNavItem('Documents', Icons.upload_file),
    _SidebarNavItem('Appointments', Icons.calendar_today),
    _SidebarNavItem('Messages', Icons.message),
    _SidebarNavItem('Notifications', Icons.notifications),
  ];

  Future<void> _logout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Color(0xFFE74C3C)),
              child: Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    try {
      await ApiService.logout();

      // Clear FCM data
      final fcmService = FCMService();
      await fcmService.clearStoredData();

      // Clear all stored data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      // Even if API call fails, clear local data and redirect to login
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (MediaQuery.of(context).size.width < 700 ||
        Theme.of(context).platform == TargetPlatform.android) {
      Navigator.of(context).pop(); // Close drawer on mobile
    }
  }

  Future<Map<String, dynamic>> _fetchClientData() async {
    try {
      final data = await ApiService.getClientProfile();
      final prefs = await SharedPreferences.getInstance();

      // Update stored data with fresh data from API
      await prefs.setInt('user_id', data['id'] ?? 0);
      await prefs.setString('user_first_name', data['first_name'] ?? '');
      await prefs.setString('user_last_name', data['last_name'] ?? '');
      await prefs.setString('user_email', data['email'] ?? '');
      await prefs.setString('client_id', data['client_id'] ?? '');
      await prefs.setString('user_gender', data['gender'] ?? '');
      await prefs.setString('user_age', data['age'] ?? '');
      await prefs.setString(
        'user_marital_status',
        data['marital_status'] ?? '',
      );
      await prefs.setString('user_phone1', data['phone_number1'] ?? '');
      await prefs.setString('user_phone2', data['phone_number2'] ?? '');
      await prefs.setString('user_phone3', data['phone_number3'] ?? '');
      await prefs.setString('user_address', data['address'] ?? '');
      await prefs.setString('user_city', data['city'] ?? '');
      await prefs.setString('user_state', data['state'] ?? '');
      await prefs.setString('user_post_code', data['post_code'] ?? '');
      await prefs.setString('user_country', data['country'] ?? '');

      // Store additional fields from the API response
      await prefs.setString('contact_type1', data['contact_type1'] ?? '');
      await prefs.setString('contact_type2', data['contact_type2'] ?? '');
      await prefs.setString('contact_type3', data['contact_type3'] ?? '');
      await prefs.setString('email_type', data['email_type'] ?? '');
      await prefs.setString('email2', data['email2'] ?? '');
      await prefs.setBool('phone_verify', data['phone_verify'] ?? false);
      await prefs.setBool('email_verify', data['email_verify'] ?? false);
      await prefs.setString('visa_type', data['visa_type'] ?? '');
      await prefs.setString('visa_expiry', data['visa_expiry'] ?? '');
      await prefs.setString('preferred_intake', data['preferred_intake'] ?? '');
      await prefs.setString('passport_country', data['passport_country'] ?? '');
      await prefs.setString('passport_number', data['passport_number'] ?? '');
      await prefs.setString(
        'nominated_occupation',
        data['nominated_occupation'] ?? '',
      );
      await prefs.setString('skill_assessment', data['skill_assessment'] ?? '');
      await prefs.setString(
        'highest_qualification_aus',
        data['highest_qualification_aus'] ?? '',
      );
      await prefs.setString(
        'highest_qualification_overseas',
        data['highest_qualification_overseas'] ?? '',
      );
      await prefs.setString('work_exp_aus', data['work_exp_aus'] ?? '');
      await prefs.setString(
        'work_exp_overseas',
        data['work_exp_overseas'] ?? '',
      );
      await prefs.setString('english_score', data['english_score'] ?? '');
      await prefs.setString('theme_mode', data['theme_mode'] ?? 'light');

      return data;
    } catch (e) {
      // If API call fails, return stored data as fallback
      final prefs = await SharedPreferences.getInstance();
      return {
        'id': prefs.getInt('user_id') ?? 0,
        'first_name': prefs.getString('user_first_name') ?? '',
        'last_name': prefs.getString('user_last_name') ?? '',
        'email': prefs.getString('user_email') ?? '',
        'client_id': prefs.getString('client_id') ?? '',
        'gender': prefs.getString('user_gender') ?? '',
        'age': prefs.getString('user_age') ?? '',
        'marital_status': prefs.getString('user_marital_status') ?? '',
        'phone_number1': prefs.getString('user_phone1') ?? '',
        'phone_number2': prefs.getString('user_phone2') ?? '',
        'phone_number3': prefs.getString('user_phone3') ?? '',
        'address': prefs.getString('user_address') ?? '',
        'city': prefs.getString('user_city') ?? '',
        'state': prefs.getString('user_state') ?? '',
        'post_code': prefs.getString('user_post_code') ?? '',
        'country': prefs.getString('user_country') ?? '',
        'contact_type1': prefs.getString('contact_type1') ?? '',
        'contact_type2': prefs.getString('contact_type2') ?? '',
        'contact_type3': prefs.getString('contact_type3') ?? '',
        'email_type': prefs.getString('email_type') ?? '',
        'email2': prefs.getString('email2') ?? '',
        'phone_verify': prefs.getBool('phone_verify') ?? false,
        'email_verify': prefs.getBool('email_verify') ?? false,
        'visa_type': prefs.getString('visa_type') ?? '',
        'visa_expiry': prefs.getString('visa_expiry') ?? '',
        'preferred_intake': prefs.getString('preferred_intake') ?? '',
        'passport_country': prefs.getString('passport_country') ?? '',
        'passport_number': prefs.getString('passport_number') ?? '',
        'nominated_occupation': prefs.getString('nominated_occupation') ?? '',
        'skill_assessment': prefs.getString('skill_assessment') ?? '',
        'highest_qualification_aus':
            prefs.getString('highest_qualification_aus') ?? '',
        'highest_qualification_overseas':
            prefs.getString('highest_qualification_overseas') ?? '',
        'work_exp_aus': prefs.getString('work_exp_aus') ?? '',
        'work_exp_overseas': prefs.getString('work_exp_overseas') ?? '',
        'english_score': prefs.getString('english_score') ?? '',
        'theme_mode': prefs.getString('theme_mode') ?? 'light',
      };
    }
  }

  Widget _buildSidebar({bool isDrawer = false}) {
    final bool isCollapsed = _sidebarCollapsed && !isDrawer;
    final double sidebarWidth = isCollapsed ? 64 : 240;
    return Container(
      width: sidebarWidth,
      color: const Color(0xFFE9EDF3),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: 32.0,
              horizontal: isCollapsed ? 0 : 16,
            ),
            child: Row(
              mainAxisAlignment:
                  isCollapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
              children: [
                Icon(Icons.gavel, color: Color(0xFF30475E), size: 32),
                if (!isCollapsed) ...[
                  SizedBox(width: 12),
                  Text(
                    'LegiComply',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF30475E),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ...List.generate(_navItems.length, (i) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 8.0),
              child: ListTile(
                leading: Icon(
                  _navItems[i].icon,
                  color:
                      i == _selectedIndex
                          ? Color(0xFF30475E)
                          : Color(0xFF5E8B7E),
                ),
                title:
                    isCollapsed
                        ? null
                        : Text(
                          _navItems[i].label,
                          style: TextStyle(
                            fontWeight:
                                i == _selectedIndex
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                            color:
                                i == _selectedIndex
                                    ? Color(0xFF30475E)
                                    : Color(0xFF5E8B7E),
                          ),
                        ),
                selected: i == _selectedIndex,
                selectedTileColor: Color(0xFFD6DEE8),
                onTap: () => _onNavTap(i),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isCollapsed ? 0 : 16,
                  vertical: 4,
                ),
              ),
            );
          }),
          Spacer(),
          if (!isCollapsed)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _fetchClientData(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final user = snapshot.data!;
                    return UserNav(
                      userName: "${user['first_name']} ${user['last_name']}",
                      userEmail: user['email'],
                      avatarUrl: "https://placehold.co/100x100.png",
                    );
                  }
                  return UserNav(
                    userName: "Loading...",
                    userEmail: "loading@example.com",
                    avatarUrl: "https://placehold.co/100x100.png",
                  );
                },
              ),
            ),
          // Logout button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 8.0),
            child: ListTile(
              leading: Icon(
                Icons.logout,
                color: Color(0xFFE74C3C), // Red color for logout
              ),
              title:
                  isCollapsed
                      ? null
                      : Text(
                        'Logout',
                        style: TextStyle(
                          color: Color(0xFFE74C3C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              onTap: _logout,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 0 : 16,
                vertical: 4,
              ),
            ),
          ),
          if (!isDrawer)
            IconButton(
              icon: Icon(isCollapsed ? Icons.arrow_right : Icons.arrow_left),
              tooltip: isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
              onPressed:
                  () => setState(() => _sidebarCollapsed = !_sidebarCollapsed),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final bool isMobile =
        MediaQuery.of(context).size.width < 700 ||
        Theme.of(context).platform == TargetPlatform.android;
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9EDF3))),
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: Icon(Icons.menu, color: Color(0xFF30475E)),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              tooltip: 'Open sidebar',
            ),
          Expanded(child: SizedBox()),
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF30475E)),
            onPressed: () {
              setState(() {
                // Trigger rebuild by changing a state variable
                _selectedIndex = _selectedIndex;
              });
            },
            tooltip: 'Refresh data',
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.notifications_none, color: Color(0xFF30475E)),
            onPressed: () {},
            tooltip: 'Toggle notifications',
          ),
          SizedBox(width: 8),
          FutureBuilder<Map<String, dynamic>>(
            future: _fetchClientData(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final user = snapshot.data!;
                return UserNav(
                  userName: "${user['first_name']} ${user['last_name']}",
                  userEmail: user['email'],
                  avatarUrl: "https://placehold.co/100x100.png",
                );
              }
              return UserNav(
                userName: "Loading...",
                userEmail: "loading@example.com",
                avatarUrl: "https://placehold.co/100x100.png",
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Expanded(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  // Trigger rebuild by changing a state variable
                  _selectedIndex = _selectedIndex;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedIndex == 0) ...[
                        FutureBuilder<Map<String, dynamic>>(
                          future: _fetchClientData(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final user = snapshot.data!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome, ${user['first_name'] ?? 'User'} ${user['last_name'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF30475E),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Here's an overview of your case and pending actions.",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF5E8B7E),
                                    ),
                                  ),
                                  SizedBox(height: 32),
                                  Wrap(
                                    spacing: 24,
                                    runSpacing: 24,
                                    children: [
                                      _dashboardCard('Case Status'),
                                      _dashboardCard('Appointments'),
                                      _dashboardCard('Document Management'),
                                      _dashboardCard('Your Information'),
                                      _dashboardCard(
                                        'Notify Us of Important Changes',
                                      ),
                                      _dashboardCard('Messages'),
                                      _dashboardCard('Notifications'),
                                    ],
                                  ),
                                ],
                              );
                            } else if (snapshot.hasError) {
                              return Text(
                                'Error loading data: ${snapshot.error}',
                              );
                            }
                            return Center(child: CircularProgressIndicator());
                          },
                        ),
                      ] else if (_selectedIndex == 1) ...[
                        FutureBuilder<Map<String, dynamic>>(
                          future: _fetchClientData(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return ClientFormPage(
                                initialData: snapshot.data!,
                              );
                            } else if (snapshot.hasError) {
                              return Text(
                                'Error loading data: ${snapshot.error}',
                              );
                            }
                            return Center(child: CircularProgressIndicator());
                          },
                        ),
                      ] else if (_selectedIndex == 2) ...[
                        DocumentUploadPage(),
                      ] else if (_selectedIndex == 3) ...[
                        AppointmentsPage(),
                      ] else if (_selectedIndex == 4) ...[
                        MessagesPage(),
                      ] else ...[
                        Text(
                          _navItems[_selectedIndex].label,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF30475E),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text('Section content goes here...'),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardCard(String title) {
    return SizedBox(
      width: 420,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF30475E),
                ),
              ),
              SizedBox(height: 8),
              if (title == 'Case Status')
                CaseStatusTracker()
              else if (title == 'Appointments')
                AppointmentScheduler()
              else if (title == 'Document Management')
                DocumentUploader()
              else
                Text(
                  'Section content goes here...',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Color(0xFF5E8B7E),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile =
        MediaQuery.of(context).size.width < 700 ||
        Theme.of(context).platform == TargetPlatform.android;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF0F4F8),
      drawer: isMobile ? Drawer(child: _buildSidebar(isDrawer: true)) : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }
}

class _SidebarNavItem {
  final String label;
  final IconData icon;
  _SidebarNavItem(this.label, this.icon);
}

// Update DashboardPage to use DashboardScaffold
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    return DashboardScaffold();
  }
}

class ClientFormPage extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const ClientFormPage({super.key, required this.initialData});
  @override
  ClientFormPageState createState() => ClientFormPageState();
}

class ClientFormPageState extends State<ClientFormPage> {
  final _formKey = GlobalKey<FormState>();
  // Personal Info
  String firstName = '';
  String lastName = '';
  String gender = '';
  DateTime? dob;
  String age = '';
  String clientId = 'ARSH230525680';
  String maritalStatus = '';

  @override
  void initState() {
    super.initState();
    // Populate form fields with initial data
    final data = widget.initialData;
    firstName = data['first_name'] ?? '';
    lastName = data['last_name'] ?? '';
    gender = data['gender'] ?? '';
    age = data['age'] ?? '';
    clientId = data['client_id'] ?? '';
    maritalStatus = data['marital_status'] ?? '';
    // Contact Info
    contactType1 = data['contact_type1'] ?? 'Not In Use';
    phoneNumber1 = data['phone_number1'] ?? '';
    contactType2 = data['contact_type2'] ?? 'Personal';
    phoneNumber2 = data['phone_number2'] ?? '';
    contactType3 = data['contact_type3'] ?? 'Secondary';
    phoneNumber3 = data['phone_number3'] ?? '';
    emailType = data['email_type'] ?? 'Personal';
    email = data['email'] ?? '';
    email2 = data['email2'] ?? '';
    phoneVerify = data['phone_verify']?.toString() ?? '';
    emailVerify = data['email_verify']?.toString() ?? '';
    // Visa/Passport
    visaType = data['visa_type'] ?? '';
    visaExpiry = data['visa_expiry'] ?? '';
    preferredIntake = data['preferred_intake'] ?? '';
    passportCountry = data['passport_country'] ?? '';
    passportNumber = data['passport_number'] ?? '';
    // Address
    address = data['address'] ?? '';
    city = data['city'] ?? '';
    state = data['state'] ?? '';
    postCode = data['post_code'] ?? '';
    country = data['country'] ?? '';
    // Education/Work
    nominatedOccupation = data['nominated_occupation'] ?? '';
    skillAssessment = data['skill_assessment'] ?? '';
    highestQualificationAus = data['highest_qualification_aus'] ?? '';
    highestQualificationOverseas = data['highest_qualification_overseas'] ?? '';
    workExpAus = data['work_exp_aus'] ?? '';
    workExpOverseas = data['work_exp_overseas'] ?? '';
    englishScore = data['english_score'] ?? '';
  }

  // Contact Info
  String contactType1 = 'Not In Use';
  String phoneNumber1 = '';
  String contactType2 = 'Personal';
  String phoneNumber2 = '';
  String contactType3 = 'Secondary';
  String phoneNumber3 = '';
  String emailType = 'Personal';
  String email = '';
  String email2 = '';
  String phoneVerify = '';
  String emailVerify = '';

  // Visa/Passport
  String visaType = '';
  String visaExpiry = '';
  String preferredIntake = '';
  String passportCountry = '';
  String passportNumber = '';

  // Address
  String address = '';
  String city = '';
  String state = '';
  String postCode = '';
  String country = '';

  // Education/Work
  String nominatedOccupation = '';
  String skillAssessment = '';
  String highestQualificationAus = '';
  String highestQualificationOverseas = '';
  String workExpAus = '';
  String workExpOverseas = '';
  String englishScore = '';

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // Collect all data into a map matching the API specification
      final data = {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'gender': gender.toLowerCase(),
        'dob': dob?.toIso8601String(),
        'age': int.tryParse(age) ?? 0,
        'marital_status': maritalStatus.toLowerCase(),
        'phone_number1': phoneNumber1,
        'contact_type1': contactType1.toLowerCase(),
        'phone_number2': phoneNumber2.isNotEmpty ? phoneNumber2 : null,
        'contact_type2': contactType2.toLowerCase(),
        'phone_number3': phoneNumber3.isNotEmpty ? phoneNumber3 : null,
        'contact_type3': contactType3.toLowerCase(),
        'email_type': emailType.toLowerCase(),
        'email2': email2.isNotEmpty ? email2 : null,
        'phone_verify': phoneVerify == 'true' || phoneVerify == '1',
        'email_verify': emailVerify == 'true' || emailVerify == '1',
        'visa_type': visaType,
        'visa_expiry': visaExpiry,
        'preferred_intake': preferredIntake,
        'passport_country': passportCountry,
        'passport_number': passportNumber,
        'address': address,
        'city': city,
        'state': state,
        'post_code': postCode,
        'country': country,
        'nominated_occupation': nominatedOccupation,
        'skill_assessment': skillAssessment,
        'highest_qualification_aus': highestQualificationAus,
        'highest_qualification_overseas': highestQualificationOverseas,
        'work_exp_aus': workExpAus,
        'work_exp_overseas': workExpOverseas,
        'english_score': englishScore,
        'themeMode': 'light', // Default theme mode
      };
      try {
        final responseData = await ApiService.updateClientProfile(data);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseData['message'] ??
                  'Client information updated successfully',
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update client information: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Information',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'First Name *'),
                      controller: TextEditingController(text: firstName),
                      onChanged: (v) => firstName = v,
                      validator:
                          (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Last Name *'),
                      controller: TextEditingController(text: lastName),
                      onChanged: (v) => lastName = v,
                      validator:
                          (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Gender *'),
                      value: gender.isNotEmpty ? gender : null,
                      items:
                          ['Male', 'Female', 'Other']
                              .map(
                                (g) =>
                                    DropdownMenuItem(value: g, child: Text(g)),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => gender = v ?? ''),
                      validator:
                          (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Date of Birth'),
                      initialValue: widget.initialData['dob'] ?? '',
                      onChanged: (v) => {}, // Add date picker if needed
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Age'),
                      initialValue: age,
                      onChanged: (v) => age = v,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Client ID'),
                      initialValue: clientId,
                      enabled: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Marital Status'),
                value: maritalStatus.isNotEmpty ? maritalStatus : null,
                items:
                    ['Never Married', 'Married', 'Divorced', 'Widowed']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged: (v) => setState(() => maritalStatus = v ?? ''),
              ),
              const SizedBox(height: 32),
              Text(
                'Contact Information',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              // Contact 1
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Contact Type *'),
                      value: contactType1,
                      items:
                          ['Not In Use', 'Personal', 'Secondary']
                              .map(
                                (t) =>
                                    DropdownMenuItem(value: t, child: Text(t)),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => contactType1 = v ?? ''),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Phone Number'),
                      initialValue: phoneNumber1,
                      onChanged: (v) => phoneNumber1 = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Contact 2
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Contact Type *'),
                      value: contactType2,
                      items:
                          ['Not In Use', 'Personal', 'Secondary']
                              .map(
                                (t) =>
                                    DropdownMenuItem(value: t, child: Text(t)),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => contactType2 = v ?? ''),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Phone Number'),
                      initialValue: phoneNumber2,
                      onChanged: (v) => phoneNumber2 = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Contact 3
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Contact Type *'),
                      value: contactType3,
                      items:
                          ['Not In Use', 'Personal', 'Secondary']
                              .map(
                                (t) =>
                                    DropdownMenuItem(value: t, child: Text(t)),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => contactType3 = v ?? ''),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Phone Number'),
                      initialValue: phoneNumber3,
                      onChanged: (v) => phoneNumber3 = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Email Type *'),
                      value: emailType,
                      items:
                          ['Personal', 'Secondary']
                              .map(
                                (t) =>
                                    DropdownMenuItem(value: t, child: Text(t)),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => emailType = v ?? ''),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Email *'),
                      initialValue: email,
                      onChanged: (v) => email = v,
                      validator:
                          (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Additional email/phone
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Email'),
                      onChanged: (v) => email2 = v,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Phone'),
                      initialValue: phoneVerify,
                      onChanged: (v) => phoneVerify = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Visa & Passport',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Visa Type'),
                      initialValue: visaType,
                      onChanged: (v) => visaType = v,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Visa Expiry Date',
                      ),
                      onChanged: (v) => visaExpiry = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Preferred Intake',
                      ),
                      onChanged: (v) => preferredIntake = v,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Country of Passport',
                      ),
                      onChanged: (v) => passportCountry = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Passport Number'),
                initialValue: passportNumber,
                onChanged: (v) => passportNumber = v,
              ),
              const SizedBox(height: 32),
              Text('Address', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Address'),
                initialValue: address,
                onChanged: (v) => address = v,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'City'),
                      initialValue: city,
                      onChanged: (v) => city = v,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'State'),
                      initialValue: state,
                      onChanged: (v) => state = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Post Code'),
                      initialValue: postCode,
                      onChanged: (v) => postCode = v,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(labelText: 'Country'),
                      onChanged: (v) => country = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Education & Work',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Nominated Occupation'),
                initialValue: nominatedOccupation,
                onChanged: (v) => nominatedOccupation = v,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Skill Assessment'),
                value: skillAssessment.isNotEmpty ? skillAssessment : null,
                items:
                    ['Select', 'Yes', 'No']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                onChanged: (v) => setState(() => skillAssessment = v ?? ''),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Highest Qualification in Australia',
                ),
                initialValue: highestQualificationAus,
                onChanged: (v) => highestQualificationAus = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Highest Qualification Overseas',
                ),
                initialValue: highestQualificationOverseas,
                onChanged: (v) => highestQualificationOverseas = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Relevant work experience in Australia',
                ),
                initialValue: workExpAus,
                onChanged: (v) => workExpAus = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Relevant work experience in Overseas',
                ),
                initialValue: workExpOverseas,
                onChanged: (v) => workExpOverseas = v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(labelText: 'Overall English score'),
                initialValue: englishScore,
                onChanged: (v) => englishScore = v,
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Submit Information',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DocumentUploadPage extends StatefulWidget {
  const DocumentUploadPage({super.key});
  @override
  DocumentUploadPageState createState() => DocumentUploadPageState();
}

class DocumentUploadPageState extends State<DocumentUploadPage> {
  String? pickedFilePath;
  String? pickedFileName;

  Future<void> _uploadDocument() async {
    if (pickedFilePath != null) {
      try {
        final responseData = await ApiService.uploadDocument(
          pickedFilePath!,
          pickedFileName ?? 'Document',
          'Document uploaded from client portal',
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseData['message'] ?? 'Document uploaded successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Clear the selected file
        setState(() {
          pickedFilePath = null;
          pickedFileName = null;
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              final result = await FilePicker.platform.pickFiles();
              if (result != null) {
                setState(() {
                  pickedFilePath = result.files.single.path;
                });
              }
            },
            child: Text('Select Document'),
          ),
          if (pickedFilePath != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Selected file: $pickedFilePath'),
            ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _uploadDocument,
            child: Text('Upload to CRM'),
          ),
        ],
      ),
    );
  }
}

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});
  @override
  AppointmentsPageState createState() => AppointmentsPageState();
}

class AppointmentsPageState extends State<AppointmentsPage> {
  List<Map<String, dynamic>> appointments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    try {
      final data = await ApiService.getClientAppointments();
      setState(() {
        // Extract the appointments list from the API response
        if (data['data'] is List) {
          appointments = List<Map<String, dynamic>>.from(data['data'] as List);
        } else if (data is List) {
          appointments = List<Map<String, dynamic>>.from(data as List);
        } else {
          appointments = [];
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        appointments = [];
        isLoading = false;
      });
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String timeStr) {
    try {
      final time = DateTime.parse('2000-01-01 $timeStr');
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timeStr;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF5E8B7E);
      case 'pending':
        return const Color(0xFFF39C12);
      case 'cancelled':
        return Colors.redAccent;
      default:
        return const Color(0xFFB0B7C3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appointments',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 16),
          if (isLoading)
            Center(child: CircularProgressIndicator())
          else if (appointments.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 64,
                    color: Color(0xFFB0B7C3),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No appointments scheduled',
                    style: TextStyle(fontSize: 18, color: Color(0xFF5E8B7E)),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  appointment['title'] ?? 'Appointment',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF30475E),
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _statusColor(
                                    appointment['status'] ?? 'pending',
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  appointment['status'] ?? 'pending',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: _statusColor(
                                      appointment['status'] ?? 'pending',
                                    ),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          if (appointment['description'] != null)
                            Text(
                              appointment['description'],
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Color(0xFF5E8B7E),
                              ),
                            ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Color(0xFFB0B7C3),
                              ),
                              SizedBox(width: 8),
                              Text(
                                _formatDate(
                                  appointment['appointment_date'] ?? '',
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Color(0xFF30475E),
                                ),
                              ),
                              SizedBox(width: 24),
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Color(0xFFB0B7C3),
                              ),
                              SizedBox(width: 8),
                              Text(
                                _formatTime(
                                  appointment['appointment_time'] ?? '',
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Color(0xFF30475E),
                                ),
                              ),
                              if (appointment['duration'] != null) ...[
                                SizedBox(width: 24),
                                Icon(
                                  Icons.timer,
                                  size: 16,
                                  color: Color(0xFFB0B7C3),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  '${appointment['duration']} min',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Color(0xFF30475E),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (appointment['location'] != null) ...[
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Color(0xFFB0B7C3),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  appointment['location'],
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Color(0xFF30475E),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (appointment['notes'] != null) ...[
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFFF0F4F8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                appointment['notes'],
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Color(0xFF5E8B7E),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5E8B7E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateAppointmentPage(),
                  ),
                ).then((_) => _fetchAppointments());
              },
              child: Text(
                'Schedule New Appointment',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CreateAppointmentPage extends StatefulWidget {
  const CreateAppointmentPage({super.key});
  @override
  CreateAppointmentPageState createState() => CreateAppointmentPageState();
}

class CreateAppointmentPageState extends State<CreateAppointmentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _duration = 60;
  bool _isLoading = false;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select date and time')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Format date and time for API
      final dateStr =
          '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      final timeStr =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';

      final responseData = await ApiService.createAppointment({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'appointment_date': dateStr,
        'appointment_time': timeStr,
        'duration': _duration,
        'location': _locationController.text,
        'notes': _notesController.text,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            responseData['message'] ?? 'Appointment created successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule Appointment'),
        backgroundColor: Color(0xFF5E8B7E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Appointment',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Visa Consultation',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Brief description of the appointment',
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),

              // Date and Time Row
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date *',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                              : 'Select date',
                          style: TextStyle(
                            color: _selectedDate != null ? null : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _selectTime,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Time *',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          _selectedTime != null
                              ? _selectedTime!.format(context)
                              : 'Select time',
                          style: TextStyle(
                            color: _selectedTime != null ? null : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Duration
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: 'Duration (minutes)',
                  border: OutlineInputBorder(),
                ),
                value: _duration,
                items:
                    [30, 45, 60, 90, 120].map((duration) {
                      return DropdownMenuItem(
                        value: duration,
                        child: Text('$duration minutes'),
                      );
                    }).toList(),
                onChanged: (value) {
                  setState(() {
                    _duration = value ?? 60;
                  });
                },
              ),
              SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Office, Video Call',
                ),
              ),
              SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  border: OutlineInputBorder(),
                  hintText: 'Additional notes or instructions',
                ),
                maxLines: 3,
              ),
              SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5E8B7E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                            'Schedule Appointment',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});
  @override
  MessagesPageState createState() => MessagesPageState();
}

class MessagesPageState extends State<MessagesPage> {
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    try {
      final data = await ApiService.getClientMessages();
      setState(() {
        // Extract the messages list from the API response
        if (data['data'] is List) {
          messages = List<Map<String, dynamic>>.from(data['data'] as List);
        } else if (data is List) {
          messages = List<Map<String, dynamic>>.from(data as List);
        } else {
          messages = [];
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        messages = [];
        isLoading = false;
      });
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes} minutes ago';
        }
        return '${difference.inHours} hours ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  Color _getSenderColor(String sender) {
    switch (sender.toLowerCase()) {
      case 'admin':
        return const Color(0xFF5E8B7E);
      case 'lawyer':
        return const Color(0xFF30475E);
      case 'system':
        return const Color(0xFFF39C12);
      default:
        return const Color(0xFFB0B7C3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Messages',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              ElevatedButton.icon(
                onPressed: () => _showSendMessageDialog(),
                icon: Icon(Icons.send, size: 18),
                label: Text('Send Message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF5E8B7E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (isLoading)
            Center(child: CircularProgressIndicator())
          else if (messages.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.message_outlined,
                    size: 64,
                    color: Color(0xFFB0B7C3),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No messages yet',
                    style: TextStyle(fontSize: 18, color: Color(0xFF5E8B7E)),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You\'ll see important updates and notifications here',
                    style: TextStyle(fontSize: 14, color: Color(0xFFB0B7C3)),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showSendMessageDialog(),
                    icon: Icon(Icons.send, size: 18),
                    label: Text('Send Your First Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF5E8B7E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () {
                        // Mark as read and show full message
                        _showMessageDetails(message);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getSenderColor(
                                      message['sender'] ?? 'system',
                                    ).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    message['sender'] ?? 'System',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: _getSenderColor(
                                        message['sender'] ?? 'system',
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  _formatDate(message['created_at'] ?? ''),
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Color(0xFFB0B7C3),
                                  ),
                                ),
                                if (message['read'] == false) ...[
                                  SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF5E8B7E),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              message['subject'] ?? 'No Subject',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF30475E),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              message['message'] ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Color(0xFF5E8B7E),
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showMessageDetails(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSenderColor(
                        message['sender'] ?? 'system',
                      ).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message['sender'] ?? 'System',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: _getSenderColor(message['sender'] ?? 'system'),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Spacer(),
                  Text(
                    _formatDate(message['created_at'] ?? ''),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Color(0xFFB0B7C3),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                message['subject'] ?? 'No Subject',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF30475E),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              message['message'] ?? '',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Color(0xFF5E8B7E),
                height: 1.5,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showSendMessageDialog() {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    bool isSending = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Send Message',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF30475E),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send a message to your legal team',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Color(0xFF5E8B7E),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: subjectController,
                      decoration: InputDecoration(
                        labelText: 'Subject *',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Question about visa process',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a subject';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: messageController,
                      decoration: InputDecoration(
                        labelText: 'Message *',
                        border: OutlineInputBorder(),
                        hintText: 'Type your message here...',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 5,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a message';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSending ? null : () => Navigator.of(context).pop(),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      isSending
                          ? null
                          : () async {
                            if (subjectController.text.isEmpty ||
                                messageController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please fill in all fields'),
                                ),
                              );
                              return;
                            }

                            setState(() {
                              isSending = true;
                            });

                            // Store context-dependent objects before async operation
                            final scaffoldMessenger = ScaffoldMessenger.of(
                              context,
                            );
                            final navigator = Navigator.of(context);

                            try {
                              final responseData =
                                  await ApiService.sendMessage({
                                    'subject': subjectController.text,
                                    'message': messageController.text,
                                  });

                              if (!mounted) return;
                              navigator.pop();
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    responseData['message'] ??
                                        'Message sent successfully',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              // Refresh messages list
                              _fetchMessages();
                            } catch (e) {
                              if (!mounted) return;
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('Error sending message: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  isSending = false;
                                });
                              }
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5E8B7E),
                    foregroundColor: Colors.white,
                  ),
                  child:
                      isSending
                          ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text('Send Message'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class DocumentUploader extends StatefulWidget {
  const DocumentUploader({super.key});

  @override
  State<DocumentUploader> createState() => _DocumentUploaderState();
}

class _DocumentUploaderState extends State<DocumentUploader> {
  String? pickedFileName;
  List<Map<String, String>> documents = [];

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    try {
      final data = await ApiService.getClientDocuments();
      final List<Map<String, String>> newDocuments = [];

      if (data is List) {
        final dataList = data as List;
        for (final doc in dataList) {
          newDocuments.add({
            'name': (doc['title'] ?? '').toString(),
            'status': (doc['status'] ?? 'pending').toString(),
            'date': (doc['created_at'] ?? '-').toString(),
            'file_type': (doc['file_type'] ?? '').toString(),
            'file_size': (doc['file_size'] ?? '').toString(),
          });
        }
      } else if (data is Map && data['data'] is List) {
        final dataList = data['data'] as List;
        for (final doc in dataList) {
          newDocuments.add({
            'name': (doc['title'] ?? '').toString(),
            'status': (doc['status'] ?? 'pending').toString(),
            'date': (doc['created_at'] ?? '-').toString(),
            'file_type': (doc['file_type'] ?? '').toString(),
            'file_size': (doc['file_size'] ?? '').toString(),
          });
        }
      }

      setState(() {
        documents = newDocuments;
      });
    } catch (e) {
      // Handle error silently or show message
      setState(() {
        documents = [];
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF5E8B7E); // Muted teal
      case 'pending':
        return const Color(0xFF30475E); // Deep blue
      case 'rejected':
        return Colors.redAccent;
      case 'under_review':
        return const Color(0xFFF39C12); // Orange
      default:
        return const Color(0xFFB0B7C3); // Gray
    }
  }

  String _formatFileSize(String sizeStr) {
    try {
      final size = int.tryParse(sizeStr) ?? 0;
      if (size < 1024) {
        return '${size}B';
      } else if (size < 1024 * 1024) {
        return '${(size / 1024).toStringAsFixed(1)}KB';
      } else {
        return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.name.isNotEmpty) {
      setState(() {
        pickedFileName = result.files.single.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file, size: 48, color: Color(0xFFB0B7C3)),
                const SizedBox(height: 16),
                Text(
                  'Drag & drop files or click to upload',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF30475E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Supported formats: PDF, JPG, PNG. Max size: 10MB.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Color(0xFF5E8B7E),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: Icon(Icons.upload, size: 20),
                  label: Text(
                    'Select Files',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5E8B7E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                if (pickedFileName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      'Selected file: $pickedFileName',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Color(0xFF5E8B7E),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Uploaded Documents',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF30475E),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF0F4F8)),
              columns: const [
                DataColumn(label: Text('Document Name')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Date Uploaded')),
                DataColumn(label: Text('Actions')),
              ],
              rows:
                  documents.map((doc) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              Icon(
                                Icons.description,
                                size: 18,
                                color: Color(0xFFB0B7C3),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                doc['name']!,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Container(
                            constraints: BoxConstraints(maxWidth: 120),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                doc['status']!,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              doc['status']!,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: _statusColor(doc['status']!),
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                        ),
                        DataCell(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                doc['date']!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Color(0xFF5E8B7E),
                                ),
                              ),
                              if (doc['file_type']!.isNotEmpty)
                                Text(
                                  '${doc['file_type']!.toUpperCase()} • ${_formatFileSize(doc['file_size']!)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Color(0xFFB0B7C3),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        DataCell(
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.download,
                                    color:
                                        doc['status']!.toLowerCase() ==
                                                'approved'
                                            ? Color(0xFF5E8B7E)
                                            : Color(0xFFB0B7C3),
                                  ),
                                  onPressed:
                                      doc['status']!.toLowerCase() == 'approved'
                                          ? () {}
                                          : null,
                                  tooltip: 'Download',
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {},
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class CaseStatusTracker extends StatelessWidget {
  const CaseStatusTracker({super.key});
  final List<Map<String, String>> steps = const [
    {'name': 'Awaiting Documents', 'status': 'completed'},
    {'name': 'Information Submitted', 'status': 'completed'},
    {'name': 'Under Review', 'status': 'current'},
    {'name': 'Application Lodged', 'status': 'upcoming'},
    {'name': 'Decision Rendered', 'status': 'upcoming'},
  ];

  Color _iconColor(String status, BuildContext context) {
    switch (status) {
      case 'completed':
        return Theme.of(context).colorScheme.primary;
      case 'current':
        return Theme.of(context).colorScheme.primary;
      case 'upcoming':
      default:
        return Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3);
    }
  }

  IconData _iconData(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'current':
        return Icons.radio_button_checked;
      case 'upcoming':
      default:
        return Icons.radio_button_unchecked;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: List.generate(steps.length, (index) {
          final step = steps[index];
          final isLast = index == steps.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Icon(
                    _iconData(step['status']!),
                    color: _iconColor(step['status']!, context),
                    size: 28,
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 36,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color:
                          step['status'] == 'completed'
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).dividerColor,
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  step['name']!,
                  style: GoogleFonts.inter(
                    fontWeight:
                        step['status'] == 'current'
                            ? FontWeight.bold
                            : FontWeight.normal,
                    color:
                        step['status'] == 'current'
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.secondary,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class AppointmentScheduler extends StatefulWidget {
  const AppointmentScheduler({super.key});
  @override
  AppointmentSchedulerState createState() => AppointmentSchedulerState();
}

class AppointmentSchedulerState extends State<AppointmentScheduler> {
  List<Map<String, dynamic>> upcomingAppointments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    try {
      final data = await ApiService.getClientAppointments();
      setState(() {
        // Extract the appointments list from the API response
        if (data['data'] is List) {
          upcomingAppointments = List<Map<String, dynamic>>.from(
            data['data'] as List,
          );
        } else if (data is List) {
          upcomingAppointments = List<Map<String, dynamic>>.from(data as List);
        } else {
          upcomingAppointments = [];
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        upcomingAppointments = [];
        isLoading = false;
      });
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatTime(String timeStr) {
    try {
      final time = DateTime.parse('2000-01-01 $timeStr');
      final hour = time.hour;
      final minute = time.minute;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).dividerColor),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          child: Center(
            child: Icon(
              Icons.calendar_month,
              size: 120,
              color: Color(0xFFB0B7C3),
            ),
          ),
        ),
        Text(
          'Upcoming Appointments',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF30475E),
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          Center(child: CircularProgressIndicator())
        else if (upcomingAppointments.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE9EDF3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'No upcoming appointments',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Color(0xFF5E8B7E),
                ),
              ),
            ),
          )
        else
          ...upcomingAppointments
              .take(3)
              .map(
                (apt) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9EDF3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              apt['title'] ?? 'Appointment',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Color(0xFF30475E),
                              ),
                            ),
                            Text(
                              '${_formatDate(apt['appointment_date'] ?? '')} at ${_formatTime(apt['appointment_time'] ?? '')}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Color(0xFF5E8B7E),
                              ),
                            ),
                            if (apt['location'] != null)
                              Text(
                                apt['location'],
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Color(0xFFB0B7C3),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            apt['status'] ?? 'pending',
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          apt['status'] ?? 'pending',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(apt['status'] ?? 'pending'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF5E8B7E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateAppointmentPage(),
                ),
              ).then((_) => _fetchAppointments());
            },
            child: Text(
              'Schedule New Appointment',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF5E8B7E);
      case 'pending':
        return const Color(0xFFF39C12);
      case 'cancelled':
        return Colors.redAccent;
      default:
        return const Color(0xFFB0B7C3);
    }
  }
}
