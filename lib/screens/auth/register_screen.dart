import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/theme_config.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth/auth_ui.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _gender = 'Male';
  String _maritalStatus = 'Single';
  String _countryCode = '+61';

  DateTime? _dob;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                Icon(Icons.error_outline_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text('Registration failed'),
              ],
            ),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    });
  }

  Future<void> _selectDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dob == null) {
      _errorMessage = 'Please select date of birth';
      _showErrorDialog(_errorMessage!);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await AuthService.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        gender: _gender,
        phone: _phoneController.text.trim(),
        countryCode: _countryCode,
        email: _emailController.text.trim(),
        dob: _dob!,
        maritalStatus: _maritalStatus,
        password: _passwordController.text.trim(),
      );

      if (result['success']) {
        setState(() {
          _successMessage = result['message'];
        });

        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: AuthRadius.borderRadius,
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: ThemeConfig.successColor,
                  ),
                  SizedBox(width: 8),
                  Text('Account created'),
                ],
              ),
              content: Text(result['message'] ?? 'Registration successful'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('Sign in'),
                ),
              ],
            );
          },
        );
      } else {
        _errorMessage = result['message'] ?? 'Registration failed';
        _showErrorDialog(_errorMessage!);
      }
    } catch (e) {
      _errorMessage = 'Unexpected error: ${e.toString()}';
      _showErrorDialog(_errorMessage!);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: ThemeConfig.navyBlue.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenShell(
      title: 'Create account',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: 'Create account',
            subtitle: 'Join the Bansal Immigration client portal',
          ),
          const SizedBox(height: 28),
          AuthFormCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sectionLabel('PERSONAL DETAILS'),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          textInputAction: TextInputAction.next,
                          decoration: authInputDecoration(
                            label: 'First name',
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: ThemeConfig.navyBlue.withValues(alpha: 0.55),
                            ),
                          ),
                          validator:
                              (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          textInputAction: TextInputAction.next,
                          decoration: authInputDecoration(label: 'Last name'),
                          validator:
                              (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: authInputDecoration(
                      label: 'Email address',
                      hint: 'you@example.com',
                      prefixIcon: Icon(
                        Icons.mail_outline_rounded,
                        color: ThemeConfig.navyBlue.withValues(alpha: 0.55),
                      ),
                    ),
                    validator:
                        (v) => v == null || v.isEmpty ? 'Enter email' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox(
                        width: 88,
                        child: TextFormField(
                          initialValue: _countryCode,
                          decoration: authInputDecoration(label: 'Code'),
                          onChanged: (v) => _countryCode = v,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: authInputDecoration(
                            label: 'Phone number',
                            hint: '400 000 000',
                            prefixIcon: Icon(
                              Icons.phone_outlined,
                              color: ThemeConfig.navyBlue.withValues(alpha: 0.55),
                            ),
                          ),
                          validator:
                              (v) =>
                                  v == null || v.isEmpty ? 'Enter phone' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel('ACCOUNT & PROFILE'),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    textInputAction: TextInputAction.next,
                    decoration: authInputDecoration(
                      label: 'Password',
                      hint: 'At least 6 characters',
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
                    validator:
                        (v) => v == null || v.isEmpty ? 'Enter password' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _gender,
                          decoration: authInputDecoration(label: 'Gender'),
                          items: const [
                            DropdownMenuItem(
                              value: 'Male',
                              child: Text('Male'),
                            ),
                            DropdownMenuItem(
                              value: 'Female',
                              child: Text('Female'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _gender = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _maritalStatus,
                          decoration: authInputDecoration(label: 'Status'),
                          items: const [
                            DropdownMenuItem(
                              value: 'Single',
                              child: Text('Single'),
                            ),
                            DropdownMenuItem(
                              value: 'Married',
                              child: Text('Married'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _maritalStatus = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _selectDob,
                    borderRadius: AuthRadius.borderRadius,
                    child: InputDecorator(
                      decoration: authInputDecoration(
                        label: 'Date of birth',
                        prefixIcon: Icon(
                          Icons.calendar_today_rounded,
                          size: 20,
                          color: ThemeConfig.navyBlue.withValues(alpha: 0.55),
                        ),
                      ),
                      child: Text(
                        _dob == null
                            ? 'Select date'
                            : DateFormat('dd MMM yyyy').format(_dob!),
                        style: TextStyle(
                          fontSize: 15,
                          color:
                              _dob == null
                                  ? AuthColors.hint
                                  : ThemeConfig.navyBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AuthPrimaryButton(
                    label: 'Create account',
                    isLoading: _isLoading,
                    onPressed: _register,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          AuthFooterLink(
            prompt: 'Already have an account?',
            actionLabel: 'Sign in',
            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
          ),
          if (_successMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ThemeConfig.successColor.withValues(alpha: 0.08),
                borderRadius: AuthRadius.borderRadius,
                border: Border.all(
                  color: ThemeConfig.successColor.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                _successMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ThemeConfig.successColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
