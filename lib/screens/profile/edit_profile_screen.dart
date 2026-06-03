import 'package:client/config/theme_config.dart';
import 'package:client/services/api_service.dart';
import 'package:client/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utils/app_loader.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postCodeController = TextEditingController();
  final _countryController = TextEditingController();

  DateTime? _selectedDateOfBirth;
  String? _selectedGender;
  String? _selectedMaritalStatus;

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _loadError;
  String? _submitError;

  static const _genders = ['Male', 'Female', 'Other'];
  static const _maritalStatuses = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
    'Other',
  ];

  // ─── Logic (unchanged) ───────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final response = await ApiService.getClientProfile();
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        _firstNameController.text = (data['first_name'] ?? '').toString();
        _lastNameController.text = (data['last_name'] ?? '').toString();
        _emailController.text = (data['email'] ?? '').toString();
        _phoneController.text = (data['phone'] ?? '').toString();
        _addressController.text = (data['address'] ?? '').toString();
        _cityController.text = (data['city'] ?? '').toString();
        _stateController.text = (data['state'] ?? '').toString();
        _postCodeController.text =
            (data['zip'] ?? data['post_code'] ?? '').toString();
        _countryController.text = (data['country'] ?? '').toString();

        final dobValue = data['dob'] ?? data['date_of_birth'];
        if (dobValue is String && dobValue.isNotEmpty) {
          _selectedDateOfBirth = DateTime.tryParse(dobValue);
        }

        final genderValue = data['gender']?.toString();
        if (genderValue != null && _genders.contains(genderValue)) {
          _selectedGender = genderValue;
        }

        final maritalStatusValue = data['marital_status']?.toString();
        if (maritalStatusValue != null &&
            _maritalStatuses.contains(maritalStatusValue)) {
          _selectedMaritalStatus = maritalStatusValue;
        }

        setState(() => _isLoading = false);
      } else {
        setState(() {
          _isLoading = false;
          _loadError =
              response['message']?.toString() ?? 'Failed to load profile data.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate =
        _selectedDateOfBirth ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select Date of Birth',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: ThemeConfig.goldenYellow,
            onPrimary: Colors.white,
            onSurface: ThemeConfig.textPrimaryLight,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDateOfBirth = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final payload = <String, dynamic>{
      'first_name': _firstNameController.text.trim(),
      if (_lastNameController.text.trim().isNotEmpty)
        'last_name': _lastNameController.text.trim(),
      if (_emailController.text.trim().isNotEmpty)
        'email': _emailController.text.trim(),
      if (_phoneController.text.trim().isNotEmpty)
        'phone': _phoneController.text.trim(),
      if (_addressController.text.trim().isNotEmpty)
        'address': _addressController.text.trim(),
      if (_cityController.text.trim().isNotEmpty)
        'city': _cityController.text.trim(),
      if (_stateController.text.trim().isNotEmpty)
        'state': _stateController.text.trim(),
      if (_postCodeController.text.trim().isNotEmpty)
        'post_code': _postCodeController.text.trim(),
      if (_countryController.text.trim().isNotEmpty)
        'country': _countryController.text.trim(),
      if (_selectedDateOfBirth != null)
        'dob': DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!),
      if (_selectedGender != null) 'gender': _selectedGender,
      if (_selectedMaritalStatus != null)
        'marital_status': _selectedMaritalStatus,
    };

    try {
      final response = await ApiService.updateClientProfile(payload);
      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _submitError =
              response['message']?.toString() ?? 'Failed to update profile.';
        });
      }
    } catch (e) {
      setState(() => _submitError = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.of(context).size.height -
        kToolbarHeight -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: ThemeConfig.backgroundLight,
      appBar: AppBar(
        backgroundColor: ThemeConfig.goldenYellow,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppResponsive.maxFormWidth,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: viewportHeight,
                      child: const Center(child: AppLoader()),
                    )
                  : _loadError != null
                      ? SizedBox(
                          height: viewportHeight,
                          child: _buildErrorState(),
                        )
                      : GestureDetector(
                          onTap: () => FocusScope.of(context).unfocus(),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Personal Information ─────────────────
                                  _SectionLabel(
                                    title: 'Personal Information',
                                    icon: Icons.person_outline_rounded,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFormCard(
                                    children: [
                                      _buildField(
                                        controller: _firstNameController,
                                        label: 'First Name *',
                                        icon: Icons.person_outline,
                                        caps: TextCapitalization.words,
                                        validator: (v) {
                                          final t = v?.trim() ?? '';
                                          if (t.isEmpty) {
                                            return 'First name is required';
                                          }
                                          if (t.length > 255) {
                                            return 'Max 255 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      _rowDivider(),
                                      _buildField(
                                        controller: _lastNameController,
                                        label: 'Last Name',
                                        icon: Icons.person_outline,
                                        caps: TextCapitalization.words,
                                        validator: (v) {
                                          if ((v?.trim() ?? '').length > 255) {
                                            return 'Max 255 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      _rowDivider(),
                                      _buildField(
                                        controller: _emailController,
                                        label: 'Email',
                                        icon: Icons.email_outlined,
                                        keyboard: TextInputType.emailAddress,
                                        validator: (v) {
                                          final t = v?.trim() ?? '';
                                          if (t.isNotEmpty &&
                                              !RegExp(
                                                r'^[\w-\.]+@([\w-]+\.)+[\w]{2,4}',
                                              ).hasMatch(t)) {
                                            return 'Enter a valid email';
                                          }
                                          if (t.length > 255) {
                                            return 'Max 255 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      _rowDivider(),
                                      _buildDateField(),
                                      _rowDivider(),
                                      _buildDropdown(
                                        label: 'Gender',
                                        icon: Icons.wc_outlined,
                                        value: _selectedGender,
                                        items: _genders,
                                        onChanged: (v) => setState(
                                          () => _selectedGender = v,
                                        ),
                                      ),
                                      _rowDivider(),
                                      _buildDropdown(
                                        label: 'Marital Status',
                                        icon: Icons.favorite_outline,
                                        value: _selectedMaritalStatus,
                                        items: _maritalStatuses,
                                        onChanged: (v) => setState(
                                          () => _selectedMaritalStatus = v,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  // ── Contact Information ──────────────────
                                  _SectionLabel(
                                    title: 'Contact Information',
                                    icon: Icons.contact_phone_outlined,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildFormCard(
                                    children: [
                                      _buildField(
                                        controller: _phoneController,
                                        label: 'Phone',
                                        icon: Icons.phone_outlined,
                                        keyboard: TextInputType.phone,
                                        validator: (v) {
                                          if ((v?.trim() ?? '').length > 255) {
                                            return 'Max 255 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      _rowDivider(),
                                      _buildField(
                                        controller: _addressController,
                                        label: 'Address',
                                        icon: Icons.home_outlined,
                                        maxLines: 2,
                                        alignHint: true,
                                        validator: (v) {
                                          if ((v?.trim() ?? '').length > 500) {
                                            return 'Max 500 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      _rowDivider(),
                                      _buildField(
                                        controller: _cityController,
                                        label: 'City',
                                        icon: Icons.location_city_outlined,
                                        caps: TextCapitalization.words,
                                        validator: (v) {
                                          if ((v?.trim() ?? '').length > 255) {
                                            return 'Max 255 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      _rowDivider(),
                                      _buildField(
                                        controller: _stateController,
                                        label: 'State',
                                        icon: Icons.map_outlined,
                                        caps: TextCapitalization.words,
                                        validator: (v) {
                                          if ((v?.trim() ?? '').length > 255) {
                                            return 'Max 255 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      _rowDivider(),
                                      _buildField(
                                        controller: _postCodeController,
                                        label: 'Post Code / ZIP',
                                        icon: Icons.markunread_mailbox_outlined,
                                        validator: (v) {
                                          if ((v?.trim() ?? '').length > 20) {
                                            return 'Max 20 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      _rowDivider(),
                                      _buildField(
                                        controller: _countryController,
                                        label: 'Country',
                                        icon: Icons.flag_outlined,
                                        caps: TextCapitalization.words,
                                        validator: (v) {
                                          if ((v?.trim() ?? '').length > 255) {
                                            return 'Max 255 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),

                                  // ── Error banner ─────────────────────────
                                  if (_submitError != null) ...[
                                    const SizedBox(height: 16),
                                    _buildErrorBanner(_submitError!),
                                  ],

                                  const SizedBox(height: 28),

                                  // ── Submit button ────────────────────────
                                  _buildSubmitButton(),

                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Form card (same card pattern as profile contact card) ───────────────────

  Widget _buildFormCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _rowDivider() => const Divider(
        height: 1,
        indent: 56,
        color: ThemeConfig.borderLight,
      );

  // ─── Field builder ────────────────────────────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FormFieldValidator<String>? validator,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization caps = TextCapitalization.none,
    int maxLines = 1,
    bool alignHint = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      textCapitalization: caps,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: ThemeConfig.textPrimaryLight,
      ),
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: alignHint,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(icon, size: 20, color: ThemeConfig.goldenYellow),
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        labelStyle: const TextStyle(
          color: ThemeConfig.textSecondaryLight,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: const TextStyle(
          color: ThemeConfig.goldenYellow,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── Dropdown builder ─────────────────────────────────────────────────────────

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(icon, size: 20, color: ThemeConfig.goldenYellow),
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        labelStyle: const TextStyle(
          color: ThemeConfig.textSecondaryLight,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        floatingLabelStyle: const TextStyle(
          color: ThemeConfig.goldenYellow,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: ThemeConfig.textPrimaryLight,
      ),
      items: items
          .map(
            (item) =>
                DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  // ─── Date field ───────────────────────────────────────────────────────────────

  Widget _buildDateField() {
    final formatted = _selectedDateOfBirth != null
        ? DateFormat('dd / MM / yyyy').format(_selectedDateOfBirth!)
        : 'Select date';

    return InkWell(
      onTap: _pickDateOfBirth,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date of Birth',
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(
              Icons.cake_outlined,
              size: 20,
              color: ThemeConfig.goldenYellow,
            ),
          ),
          suffixIcon: Icon(
            Icons.calendar_month_outlined,
            size: 18,
            color: ThemeConfig.goldenYellow,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          labelStyle: TextStyle(
            color: ThemeConfig.textSecondaryLight,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          floatingLabelStyle: TextStyle(
            color: ThemeConfig.goldenYellow,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(
          formatted,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: _selectedDateOfBirth != null
                ? ThemeConfig.textPrimaryLight
                : ThemeConfig.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  // ─── Error banner ─────────────────────────────────────────────────────────────

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: ThemeConfig.errorColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ThemeConfig.errorColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: ThemeConfig.errorColor,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: ThemeConfig.errorColor,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Submit button (same golden gradient as profile screen) ───────────────────

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: _isSubmitting
            ? null
            : const LinearGradient(
                colors: [ThemeConfig.goldenYellow, Color(0xFFD4890A)],
              ),
        color: _isSubmitting ? ThemeConfig.borderLight : null,
        boxShadow: _isSubmitting
            ? null
            : [
                BoxShadow(
                  color: ThemeConfig.goldenYellow.withValues(alpha: 0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isSubmitting ? null : _submit,
          child: Center(
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: AppLoader(size: 24),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.save_outlined, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ─── Error state ──────────────────────────────────────────────────────────────

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ThemeConfig.errorColor.withValues(alpha: 0.08),
                border: Border.all(
                  color: ThemeConfig.errorColor.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: ThemeConfig.errorColor,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ThemeConfig.textSecondaryLight,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            _RetryButton(onTap: _fetchProfile),
          ],
        ),
      ),
    );
  }
}

// ─── Section label (same as profile screen) ───────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ThemeConfig.goldenYellow, Color(0xFFD4890A)],
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 9),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: ThemeConfig.goldenYellow.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: ThemeConfig.goldenYellow),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: ThemeConfig.navyBlue,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ─── Retry button (same golden gradient) ─────────────────────────────────────

class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [ThemeConfig.goldenYellow, Color(0xFFD4890A)],
        ),
        boxShadow: [
          BoxShadow(
            color: ThemeConfig.goldenYellow.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
