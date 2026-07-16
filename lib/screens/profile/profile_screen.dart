import 'package:client/config/theme_config.dart';
import 'package:flutter/material.dart';
import 'package:client/services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_loader.dart';
import '../../utils/cache_helper.dart';
import '../../utils/responsive_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _profileCacheKey = 'client_profile_cache';

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _initProfile();
  }

  // ─── Logic ───────────────────────────────────────────────────────────────────

  Future<void> _initProfile() async {
    // Show cached profile instantly (no loader), then refresh in background.
    final cached = await CacheHelper.loadEnvelope(
      _profileCacheKey,
      maxAge: const Duration(days: 30),
    );
    if (cached is Map && mounted) {
      setState(() {
        _profileData = Map<String, dynamic>.from(cached);
        _isLoading = false;
      });
    }
    await _fetchProfile(silent: _profileData != null);
  }

  Future<void> _fetchProfile({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final result = await ApiService.getClientProfile();
      if (!mounted) return;
      if (result['success'] == true) {
        setState(() {
          _profileData = result['data'];
          _isLoading = false;
          _errorMessage = null;
        });
        await CacheHelper.saveEnvelope(
          key: _profileCacheKey,
          data: result['data'],
        );
      } else {
        // Keep showing cached data if we already have it.
        setState(() {
          if (_profileData == null) {
            _errorMessage = result['message'] ?? 'Failed to load profile';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_profileData == null) _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    await AuthService.logout(true);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Future<void> _openEditProfile() async {
    final result = await Navigator.of(context).pushNamed('/profile/edit');
    if (!mounted) return;
    if (result == true) _fetchProfile();
  }

  Future<void> _openPersonalInformation() async {
    await Navigator.of(context).pushNamed('/personal-information');
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: ThemeConfig.backgroundLight,
        appBar: _pinnedAppBar(),
        body: const Center(child: AppLoader()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: ThemeConfig.backgroundLight,
        appBar: _pinnedAppBar(),
        body: _buildErrorBody(),
      );
    }

    final data = _profileData!;
    final fullName =
        '${data["first_name"] ?? ""} ${data["last_name"] ?? ""}'.trim();
    final initial = (data['first_name'] ?? '').toString().isNotEmpty
        ? (data['first_name'] as String)[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: ThemeConfig.backgroundLight,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppResponsive.maxFormWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Floating hero card ──────────────────────────────────
                  _buildHeroCard(initial, fullName, data),

                  // ── Content ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Client ID badge
                        if ((data['client_id'] ?? '').toString().isNotEmpty)
                          _buildClientIdBadge(data['client_id'].toString()),

                        const SizedBox(height: 20),

                        // Quick-info chips: phone + city
                        _buildQuickInfoRow(data),

                        const SizedBox(height: 20),

                        // Full contact card
                        _buildContactCard(data),

                        const SizedBox(height: 28),

                        _SectionLabel(title: 'Account'),
                        const SizedBox(height: 10),
                        _buildGroupedList([
                          _GroupItem(
                            icon: Icons.person_outline_rounded,
                            label: 'Personal Information',
                            subtitle: 'View your complete details',
                            color: const Color(0xFF3D5AFE),
                            onTap: _openPersonalInformation,
                          ),
                          _GroupItem(
                            icon: Icons.edit_outlined,
                            label: 'Edit Profile',
                            subtitle: 'Update your information',
                            color: ThemeConfig.goldenYellow,
                            onTap: _openEditProfile,
                          ),
                        ]),

                        const SizedBox(height: 20),

                        _SectionLabel(title: 'Session'),
                        const SizedBox(height: 10),
                        _buildGroupedList([
                          _GroupItem(
                            icon: Icons.logout_rounded,
                            label: 'Logout',
                            subtitle: 'Sign out of your account',
                            color: ThemeConfig.errorColor,
                            onTap: () => _handleLogout(context),
                            isDestructive: true,
                          ),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Floating hero card (inset, all corners rounded) ─────────────────────────

  Widget _buildHeroCard(
    String initial,
    String fullName,
    Map<String, dynamic> data,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFC107),
            ThemeConfig.goldenYellow,
            Color(0xFFD4890A),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: ThemeConfig.goldenYellow.withValues(alpha: 0.40),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Decorative circles
            Positioned(top: -25, right: -30, child: _softCircle(160, 0.10)),
            Positioned(bottom: -30, left: -40, child: _softCircle(150, 0.08)),
            Positioned(top: 50, right: 90, child: _softCircle(60, 0.07)),

            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top bar: back / title / edit
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white),
                        onPressed: () => Navigator.of(context).maybePop(),
                        tooltip: 'Back',
                      ),
                      const Expanded(
                        child: Text(
                          'My Profile',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_outlined,
                              color: Colors.white, size: 18),
                        ),
                        onPressed: _openEditProfile,
                        tooltip: 'Edit Profile',
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Avatar — triple ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      Container(
                        width: 94,
                        height: 94,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(3),
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFFFFF8E1),
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: ThemeConfig.navyBlue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Name
                  Text(
                    fullName.isEmpty ? 'Client' : fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                      shadows: [
                        Shadow(color: Color(0x33000000), blurRadius: 8),
                      ],
                    ),
                  ),

                  const SizedBox(height: 5),

                  // Email
                  Text(
                    (data['email'] ?? '').toString(),
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.white.withValues(alpha: 0.88),
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // "Active Client" pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 12, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          'Active Client',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _softCircle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );

  // ─── Client ID badge ─────────────────────────────────────────────────────────

  Widget _buildClientIdBadge(String clientId) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: ThemeConfig.goldenYellow.withValues(alpha: 0.45),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ThemeConfig.goldenYellow.withValues(alpha: 0.2),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ThemeConfig.goldenYellow, Color(0xFFD4890A)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.badge_outlined,
                size: 15,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Client ID: $clientId',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: ThemeConfig.navyBlue,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Quick-info chips ─────────────────────────────────────────────────────────

  Widget _buildQuickInfoRow(Map<String, dynamic> data) {
    final phone = (data['phone'] ?? '').toString().trim();
    final city = (data['city'] ?? '').toString().trim();
    if (phone.isEmpty && city.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        if (phone.isNotEmpty)
          Expanded(
            child: _QuickInfoChip(icon: Icons.phone_outlined, value: phone),
          ),
        if (phone.isNotEmpty && city.isNotEmpty) const SizedBox(width: 12),
        if (city.isNotEmpty)
          Expanded(
            child: _QuickInfoChip(
              icon: Icons.location_city_outlined,
              value: city,
            ),
          ),
      ],
    );
  }

  // ─── Contact card ─────────────────────────────────────────────────────────────

  Widget _buildContactCard(Map<String, dynamic> data) {
    final rows = [
      _InfoRow(Icons.phone_outlined, 'Phone', data['phone'] ?? '—'),
      _InfoRow(Icons.home_outlined, 'Address', data['address'] ?? '—'),
      _InfoRow(Icons.location_city_outlined, 'City', data['city'] ?? '—'),
      _InfoRow(Icons.flag_outlined, 'Country', data['country'] ?? '—'),
    ];

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
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              color: ThemeConfig.goldenYellow.withValues(alpha: 0.07),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [ThemeConfig.goldenYellow, Color(0xFFD4890A)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.contact_phone_outlined,
                    size: 17,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Contact Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ThemeConfig.navyBlue,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: ThemeConfig.borderLight),
          ...List.generate(rows.length, (i) {
            return Column(
              children: [
                _buildInfoRow(rows[i]),
                if (i < rows.length - 1)
                  const Divider(
                    height: 1,
                    indent: 66,
                    color: ThemeConfig.borderLight,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoRow(_InfoRow item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: ThemeConfig.goldenYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(item.icon, size: 18, color: ThemeConfig.goldenYellow),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ThemeConfig.textSecondaryLight,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.value,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: ThemeConfig.textPrimaryLight,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Grouped action list ──────────────────────────────────────────────────────

  Widget _buildGroupedList(List<_GroupItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: List.generate(items.length, (i) {
            final item = items[i];
            return Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: item.onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              item.icon,
                              color: item.color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: item.isDestructive
                                        ? ThemeConfig.errorColor
                                        : ThemeConfig.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: ThemeConfig.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 22,
                            color: item.color.withValues(alpha: 0.45),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (i < items.length - 1)
                  const Divider(
                    height: 1,
                    indent: 72,
                    color: ThemeConfig.borderLight,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ─── Error body ───────────────────────────────────────────────────────────────

  Widget _buildErrorBody() {
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
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ThemeConfig.textSecondaryLight,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            _GoldenCta(
              label: 'Try Again',
              icon: Icons.refresh_rounded,
              onTap: _fetchProfile,
              width: 160,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Pinned AppBar ────────────────────────────────────────────────────────────

  PreferredSizeWidget _pinnedAppBar() {
    return AppBar(
      backgroundColor: ThemeConfig.goldenYellow,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Text(
        'My Profile',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});
  final String title;

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
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: ThemeConfig.textSecondaryLight,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }
}

// ─── Quick info chip ─────────────────────────────────────────────────────────

class _QuickInfoChip extends StatelessWidget {
  const _QuickInfoChip({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ThemeConfig.goldenYellow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: ThemeConfig.goldenYellow),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ThemeConfig.textPrimaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Golden CTA ───────────────────────────────────────────────────────────────

class _GoldenCta extends StatelessWidget {
  const _GoldenCta({
    required this.label,
    required this.icon,
    required this.onTap,
    this.width,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
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

// ─── Data models ─────────────────────────────────────────────────────────────

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);
}

class _GroupItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isDestructive;
  const _GroupItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isDestructive = false,
  });
}
