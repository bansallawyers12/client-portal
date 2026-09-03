import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/theme_config.dart';
import '../../../services/api_service_bansal_immigration.dart';
import '../../../utils/app_loader.dart';
import '../../../utils/cache_helper.dart';
import '../../../utils/responsive_utils.dart';

class OccupationSearchScreen extends StatefulWidget {
  const OccupationSearchScreen({super.key});

  @override
  State<OccupationSearchScreen> createState() => _OccupationSearchScreenState();
}

class _OccupationSearchScreenState extends State<OccupationSearchScreen> {
  final TextEditingController _controller = TextEditingController();

  static const String _cacheKey = "occupation_cache_v1";

  List<Map<String, dynamic>> allOccupations = [];
  List<Map<String, dynamic>> suggestions = [];
  Map<String, dynamic>? details;

  bool loading = false;
  Timer? _debounce;
  int _visaTab = 0; // 0 = Eligible, 1 = Non-Eligible

  @override
  void initState() {
    super.initState();
    _loadOccupations();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadOccupations() async {
    final prefs = await SharedPreferences.getInstance();

    // Show the cached occupation list instantly (stale-while-revalidate).
    bool hasCache = false;
    try {
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        final decoded = jsonDecode(cached);
        final List data = decoded['data'] ?? decoded ?? [];
        allOccupations =
            data.map((e) => Map<String, dynamic>.from(e)).toList();
        hasCache = allOccupations.isNotEmpty;
      }
    } catch (e) {
      debugPrint("Cache error: $e");
    }

    // Only block the UI with a loader when there's nothing cached to show.
    if (mounted) setState(() => loading = !hasCache);

    try {
      final res = await ApiServiceBansalImmigration.getAllOccupations();
      final List data = res['data'] ?? [];
      if (data.isNotEmpty) {
        allOccupations =
            data.map((e) => Map<String, dynamic>.from(e)).toList();
        await prefs.setString(_cacheKey, jsonEncode(res));
      }
    } catch (e) {
      debugPrint("API error: $e");
    }

    if (!mounted) return;
    setState(() => loading = false);
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 100), () {
      final query = value.trim().toLowerCase();

      if (query.isEmpty) {
        setState(() {
          suggestions = [];
          details = null;
        });
        return;
      }

      if (allOccupations.isEmpty) return;

      final results =
          allOccupations
              .where((item) {
                final title =
                    (item['occupation_title'] ?? '').toString().toLowerCase();
                final code =
                    (item['anzsco_code'] ?? '').toString().toLowerCase();

                return title.contains(query) || code.contains(query);
              })
              .take(8)
              .toList();

      setState(() {
        suggestions = results;
      });
    });
  }

  Future<void> _getDetails(String code) async {
    final detailKey = 'occupation_detail_${code}_v1';

    setState(() {
      suggestions.clear();
      details = null;
      _visaTab = 0;
    });

    // Occupation details are static reference data — show cache instantly.
    final cached = await CacheHelper.loadEnvelope(
      detailKey,
      maxAge: const Duration(hours: 24),
    );
    if (cached is Map && mounted) {
      setState(() {
        details = Map<String, dynamic>.from(cached);
        loading = false;
      });
    } else {
      setState(() => loading = true);
    }

    try {
      final res = await ApiServiceBansalImmigration.getOccupationDetails(code);

      final dataList = res['data'];

      if (dataList is List && dataList.isNotEmpty) {
        details = Map<String, dynamic>.from(dataList.first);
        await CacheHelper.saveEnvelope(key: detailKey, data: details);
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    if (!mounted) return;
    setState(() {
      loading = false;
    });
  }

  static const Color _navy = ThemeConfig.navyBlue;
  static const Color _gold = ThemeConfig.goldenYellow;
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF64748B);
  static const _green = Color(0xFF10B981);
  static const _red = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Occupation Search',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: ThemeConfig.goldenYellow,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppResponsive.maxContentWidth,
            ),
            child: Padding(
              padding: AppResponsive.pagePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  _searchField(),
                  const SizedBox(height: 14),
                  if (loading)
                    const Expanded(child: Center(child: AppLoader()))
                  else if (suggestions.isNotEmpty)
                    Expanded(child: _suggestionsList())
                  else if (details != null)
                    Expanded(
                      child: SingleChildScrollView(child: _buildDetails()),
                    )
                  else
                    Expanded(child: _emptyState()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: _onSearchChanged,
        style: const TextStyle(fontSize: 14.5, color: _textPrimary),
        decoration: InputDecoration(
          hintText: 'Search occupation or ANZSCO code',
          hintStyle: const TextStyle(fontSize: 14, color: _textMuted),
          prefixIcon: const Icon(Icons.search_rounded, color: _textMuted),
          suffixIcon:
              _controller.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: _textMuted,
                      size: 20,
                    ),
                    onPressed: () {
                      _controller.clear();
                      _onSearchChanged('');
                      setState(() {});
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.work_outline_rounded,
              size: 34,
              color: _gold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Search for an occupation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Type an occupation name or ANZSCO code\nto view eligible visa options.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _suggestionsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: suggestions.length,
        separatorBuilder:
            (_, _) => const Divider(height: 1, color: _border, indent: 16),
        itemBuilder: (_, i) {
          final item = suggestions[i];
          return InkWell(
            onTap: () {
              _controller.text = item['occupation_title'] ?? '';
              FocusScope.of(context).unfocus();
              _getDetails(item['anzsco_code']);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item['occupation_title'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _navy.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item['anzsco_code'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _navy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: _border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  Widget _buildDetails() {
    final visas = details!['visa_options'];
    final List entries = visas is Map
        ? visas.values.toList()
        : (visas is List ? visas : const []);
    final visaMaps = entries
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final eligible =
        visaMaps.where((v) => _asBool(v['eligibility'])).toList();
    final nonEligible =
        visaMaps.where((v) => !_asBool(v['eligibility'])).toList();
    final shown = _visaTab == 0 ? eligible : nonEligible;

    final skillLevel = details!['skill_level'];
    final salary = details!['median_salary'] ??
        details!['salary'] ??
        details!['average_salary'];
    final assessing =
        (details!['assessing_authority'] ?? '').toString().trim();

    final listTags = _occupationListTags(visaMaps);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top category tags ───────────────────────────────────────
        if (listTags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...listTags.map(_categoryTag),
              _categoryTag(
                'ANZSCO ${details!['anzsco_code']}',
                const Color(0xFFDBEAFE),
                const Color(0xFF1D4ED8),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],

        // ── Occupation summary card ─────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_navy, Color(0xFF2D3B8F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.work_rounded,
                      color: _gold,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${details!['occupation_title']}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _navy,
                            letterSpacing: -0.3,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ANZSCO ${details!['anzsco_code']}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _textMuted,
                          ),
                        ),
                        if (assessing.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            assessing,
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (skillLevel != null || salary != null) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, color: _border),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (skillLevel != null)
                      Expanded(
                        child: _statCell(
                          icon: Icons.school_rounded,
                          iconColor: _navy,
                          tint: _navy.withValues(alpha: 0.08),
                          value: 'Level $skillLevel',
                          label: _skillLevelLabel(skillLevel),
                        ),
                      ),
                    if (skillLevel != null && salary != null)
                      const SizedBox(width: 12),
                    if (salary != null)
                      Expanded(
                        child: _statCell(
                          icon: Icons.payments_rounded,
                          iconColor: _green,
                          tint: _green.withValues(alpha: 0.10),
                          value: _formatSalary(salary),
                          label: 'Median Salary',
                          valueColor: _green,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Visa eligibility header + tabs ──────────────────────────
        const Text(
          'Check visa eligibility',
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            color: _navy,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'See which visas are available for this occupation.',
          style: TextStyle(fontSize: 12.5, color: _textMuted),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _visaTabButton(
                  label: 'Eligible Visa',
                  selected: _visaTab == 0,
                  count: eligible.length,
                  onTap: () => setState(() => _visaTab = 0),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _visaTabButton(
                  label: 'Non-Eligible Visa',
                  selected: _visaTab == 1,
                  count: nonEligible.length,
                  onTap: () => setState(() => _visaTab = 1),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Text(
              _visaTab == 0 ? 'Eligible Visas' : 'Non-Eligible Visas',
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: _navy,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (_visaTab == 0 ? _green : _red).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${shown.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _visaTab == 0
                      ? const Color(0xFF047857)
                      : const Color(0xFFB91C1C),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (shown.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: _cardDecoration(),
            child: Text(
              _visaTab == 0
                  ? 'No eligible visas found for this occupation.'
                  : 'No non-eligible visas listed.',
              style: const TextStyle(fontSize: 13, color: _textMuted),
            ),
          )
        else
          Container(
            decoration: _cardDecoration(),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (int i = 0; i < shown.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: _border),
                  _visaRow(shown[i], eligible: _visaTab == 0),
                ],
                const Divider(height: 1, color: _border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: _textMuted.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Visa options may change. Please check the latest guidelines on the official website.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: _textMuted,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),
        _acronymNote(),
        const SizedBox(height: 8),
      ],
    );
  }

  List<String> _occupationListTags(List<Map<String, dynamic>> visas) {
    final fromDetails = details!['occupation_lists'];
    if (fromDetails is List && fromDetails.isNotEmpty) {
      return fromDetails.map((e) => e.toString()).toList();
    }
    const keys = ['CSOL', 'MLTSSL', 'STSOL', 'ROL'];
    final tags = <String>[];
    for (final key in keys) {
      if (visas.any((v) => _asBool(v[key]))) tags.add(key);
    }
    return tags;
  }

  Widget _categoryTag(String label, [Color? bg, Color? fg]) {
    final colors = switch (label) {
      'CSOL' => (const Color(0xFFF3E8FF), const Color(0xFF7C3AED)),
      'MLTSSL' => (const Color(0xFFDCFCE7), const Color(0xFF047857)),
      'STSOL' => (const Color(0xFFFFF4D6), const Color(0xFF9A6A00)),
      'ROL' => (const Color(0xFFE0F2FE), const Color(0xFF0369A1)),
      _ => (bg ?? const Color(0xFFDBEAFE), fg ?? const Color(0xFF1D4ED8)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: colors.$2,
        ),
      ),
    );
  }

  Widget _statCell({
    required IconData icon,
    required Color iconColor,
    required Color tint,
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? _navy,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11.5, color: _textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _visaTabButton({
    required String label,
    required bool selected,
    required int count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: selected
              ? Border.all(color: _gold.withValues(alpha: 0.55))
              : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 15, color: _navy),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                '$label ($count)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? _navy : _textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _visaRow(Map<String, dynamic> data, {required bool eligible}) {
    final type = '${data['visa_type'] ?? ''}';
    final name = '${data['visa_name'] ?? ''}';
    final style = _visaVisual(type);
    final lists = <String>[
      if (_asBool(data['MLTSSL'])) 'MLTSSL',
      if (_asBool(data['STSOL'])) 'STSOL',
      if (_asBool(data['ROL'])) 'ROL',
      if (_asBool(data['CSOL'])) 'CSOL',
    ];
    final meta = lists.isNotEmpty
        ? lists.join(' · ')
        : (eligible ? 'Eligible to apply' : 'Not eligible');

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => _showVisaDetailSheet(data, eligible: eligible),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: style.$2.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(style.$1, color: style.$2, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.isEmpty ? name : '$type $name',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _navy,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color) _visaVisual(String type) {
    return switch (type.trim()) {
      '189' => (Icons.star_rounded, const Color(0xFF7C3AED)),
      '190' => (Icons.groups_rounded, _green),
      '491' => (Icons.work_rounded, const Color(0xFF0EA5E9)),
      '482' || 'TSS' => (Icons.apartment_rounded, const Color(0xFFF59E0B)),
      '186' => (Icons.badge_rounded, _navy),
      '494' => (Icons.location_on_rounded, const Color(0xFF14B8A6)),
      _ => (Icons.airplane_ticket_rounded, _navy),
    };
  }

  void _showVisaDetailSheet(
    Map<String, dynamic> data, {
    required bool eligible,
  }) {
    final statusColor = eligible ? _green : _red;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _navy,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '${data['visa_type']}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${data['visa_name']}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      eligible ? Icons.verified_rounded : Icons.block_rounded,
                      size: 18,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      eligible ? 'Eligible to apply' : 'Not eligible',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: eligible
                            ? const Color(0xFF047857)
                            : const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'SKILLED OCCUPATION LISTS',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: _textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _listChip('MLTSSL', _asBool(data['MLTSSL'])),
                  _listChip('STSOL', _asBool(data['STSOL'])),
                  _listChip('ROL', _asBool(data['ROL'])),
                  _listChip('CSOL', _asBool(data['CSOL'])),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _skillLevelLabel(dynamic level) {
    final n = int.tryParse(level.toString()) ?? 0;
    return switch (n) {
      1 => 'Bachelor or higher',
      2 => 'Diploma / Advanced Diploma',
      3 => 'Certificate III / IV',
      4 => 'Certificate II',
      5 => 'Certificate I',
      _ => 'Skill level',
    };
  }

  String _formatSalary(dynamic salary) {
    if (salary is num) {
      return '\$${salary.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          )}/year';
    }
    final s = salary.toString();
    if (s.contains('\$')) return s;
    return '\$$s/year';
  }

  Widget _listChip(String label, bool value) {
    final color = value ? _green : _red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: value ? const Color(0xFF047857) : const Color(0xFFB91C1C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _acronymNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _navy.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 15, color: _textMuted),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'MLTSSL, STSOL, ROL and CSOL are the skilled occupation lists '
              'this occupation may appear on for each visa.',
              style: TextStyle(fontSize: 11.5, color: _textMuted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == '1' || v.toLowerCase() == 'true';
    return false;
  }
}
