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

    setState(() => loading = true);

    try {
      final cached = prefs.getString(_cacheKey);

      if (cached != null) {
        final decoded = jsonDecode(cached);

        final List data = decoded['data'] ?? decoded ?? [];

        allOccupations =
            data.map((e) => Map<String, dynamic>.from(e)).toList();

        if (!mounted) return;

        setState(() {
          loading = false;
        });

        return;
      }
    } catch (e) {
      debugPrint("Cache error: $e");
    }

    try {
      final res = await ApiServiceBansalImmigration.getAllOccupations();

      final List data = res['data'] ?? [];

      allOccupations =
          data.map((e) => Map<String, dynamic>.from(e)).toList();

      await prefs.setString(_cacheKey, jsonEncode(res));
    } catch (e) {
      debugPrint("API error: $e");
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
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

  Widget _buildDetails() {
    final visas = details!['visa_options'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${details!['anzsco_code']}",
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9A6A00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "${details!['occupation_title']}",
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _navy,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Possible Visa Options',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Table(
              border: TableBorder.all(color: _border, width: 1),
              columnWidths: const {
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(1),
                5: FlexColumnWidth(1),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                _headerRow(),
                ...visas.entries.map<TableRow>((e) => _row(e.value)).toList(),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _legend(),
        ],
      ),
    );
  }

  Widget _legend() {
    Widget item(IconData icon, Color color, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: _textMuted),
        ),
      ],
    );

    return Row(
      children: [
        item(Icons.check_circle, _green, 'Eligible'),
        const SizedBox(width: 16),
        item(Icons.cancel, _red, 'Not eligible'),
      ],
    );
  }

  TableRow _headerRow() {
    return TableRow(
      decoration: BoxDecoration(color: _navy.withValues(alpha: 0.06)),
      children: [
        _cell('Visa Type'),
        _cell('Eligibility'),
        _cell('MLTSSL'),
        _cell('STSOL'),
        _cell('ROL'),
        _cell('CSOL'),
      ],
    );
  }

  TableRow _row(Map data) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _navy,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  data['visa_type'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data['visa_name'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        _iconCell(data['eligibility']),
        _iconCell(data['MLTSSL']),
        _iconCell(data['STSOL']),
        _iconCell(data['ROL']),
        _iconCell(data['CSOL']),
      ],
    );
  }

  Widget _iconCell(bool value) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Icon(
        value ? Icons.check_circle : Icons.cancel,
        size: 17,
        color: value ? _green : _red,
      ),
    );
  }

  static Widget _cell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _navy,
        ),
      ),
    );
  }
}
