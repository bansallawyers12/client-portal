import 'package:flutter/material.dart';

import '../../config/theme_config.dart';
import '../../models/client.dart';
import '../../services/auth_service.dart';
import '../../utils/secure_storage_service.dart';
import '../../widgets/auth/auth_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _checkBiometricStatus();
    _loadSavedCredentials();
  }

  void _showErrorDialog(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: AuthRadius.borderRadius,
            ),
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text("Error"),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    });
  }

  Future<void> _loadSavedCredentials() async {
    final creds = await SecureStorageService.loadCredentials();
    setState(() {
      _rememberMe = creds['remember'] ?? false;
      if (_rememberMe) {
        _emailController.text = creds['email'] ?? '';
        _passwordController.text = creds['password'] ?? '';
      }
    });
  }

  Future<void> _saveCredentials() async {
    await SecureStorageService.saveCredentials(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      rememberMe: _rememberMe,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await AuthService.isBiometricAvailable();
    setState(() {
      _biometricAvailable = available;
    });
  }

  Future<void> _checkBiometricStatus() async {
    final enabled = await AuthService.isBiometricEnabled();
    setState(() {
      _biometricEnabled = enabled;
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await AuthService.login(
        emailOrPhone: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (result['success'] == true) {
        await _saveCredentials();
        final int? cpStatus = AuthService.cpStatus;

        setState(() {
          _successMessage = result['message'];
        });

        Future.delayed(const Duration(seconds: 1), () {
          if (cpStatus == 1) {
            Navigator.pushReplacementNamed(context, '/matters');
          } else if (cpStatus == 2) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else {
            Navigator.pushReplacementNamed(context, '/matters');
          }
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
        });

        _showErrorDialog(result['message'] ?? "Login failed");
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      });

      _showErrorDialog(_errorMessage!);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authenticated = await AuthService.authenticateWithBiometrics();

      if (authenticated) {
        setState(() {
          _successMessage = 'Biometric authentication successful!';
        });
      } else {
        setState(() {
          _errorMessage = 'Biometric authentication failed';
        });

        _showErrorDialog(_errorMessage!);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Biometric authentication error: ${e.toString()}';
      });

      _showErrorDialog(_errorMessage!);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _enableBiometric() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final enabled = await AuthService.enableBiometric();

      if (enabled) {
        setState(() {
          _biometricEnabled = true;
          _successMessage = 'Biometric authentication enabled!';
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to enable biometric authentication';
        });

        _showErrorDialog(_errorMessage!);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error enabling biometric: ${e.toString()}';
      });

      _showErrorDialog(_errorMessage!);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      final mockClient = Client(
        id: 1,
        clientId: 'test_client_001',
        name: 'Test Client',
        email: 'test@example.com',
        phone: '+1234567890',
        city: 'Test City',
        address: '123 Test Street',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        state: 'Test State',
        country: 'Test Country',
        postCode: '12345',
        gender: 'Not Specified',
        age: '25',
        maritalStatus: 'Single',
        phoneNumber1: '+1234567890',
        phoneVerify: true,
        emailVerify: true,
        themeMode: 'light',
      );

      setState(() {
        _successMessage = 'Test login successful! Navigating to dashboard...';
      });

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard',
              (Route<dynamic> route) => false,
        );
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Test login failed: ${e.toString()}';
      });

      _showErrorDialog(_errorMessage!);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenShell(
      title: 'Sign in',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: 'Welcome back',
            subtitle: 'Sign in to access your client portal',
          ),
          const SizedBox(height: 32),
          AuthFormCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: authInputDecoration(
                      label: 'Email or phone',
                      hint: 'you@example.com',
                      prefixIcon: Icon(
                        Icons.mail_outline_rounded,
                        color: ThemeConfig.navyBlue.withValues(alpha: 0.55),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email or phone';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                    decoration: authInputDecoration(
                      label: 'Password',
                      hint: 'Enter your password',
                      prefixIcon: Icon(
                        Icons.lock_outline_rounded,
                        color: ThemeConfig.navyBlue.withValues(alpha: 0.55),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AuthColors.hint,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        height: 40,
                        child: Checkbox(
                          value: _rememberMe,
                          activeColor: ThemeConfig.goldenYellow,
                          checkColor: ThemeConfig.navyBlue,
                          side: const BorderSide(color: AuthColors.border),
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                        ),
                      ),
                      const Text(
                        'Remember me',
                        style: TextStyle(
                          color: AuthColors.body,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/forgot-password');
                        },
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: ThemeConfig.goldenYellow,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AuthPrimaryButton(
                    label: 'Sign in',
                    isLoading: _isLoading,
                    onPressed: _login,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          AuthFooterLink(
            prompt: "Don't have an account?",
            actionLabel: 'Create account',
            onTap: () => Navigator.pushNamed(context, '/register'),
          ),
          if (_successMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ThemeConfig.successColor.withValues(alpha: 0.08),
                borderRadius: AuthRadius.borderRadius,
                border: Border.all(
                  color: ThemeConfig.successColor.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: ThemeConfig.successColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(
                        color: ThemeConfig.successColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
