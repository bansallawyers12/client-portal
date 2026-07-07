import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/theme_config.dart';
import '../../../models/visa_search/visa_model.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_loader.dart';
import '../../../utils/responsive_utils.dart';
import '../../../widgets/common_app_bar.dart';
import 'visa_estimate_screen.dart';

class VacSearchScreen extends StatefulWidget {
  const VacSearchScreen({super.key});

  @override
  State<VacSearchScreen> createState() => _VacSearchScreenState();
}

class _VacSearchScreenState extends State<VacSearchScreen> {
  static const String _visaCacheKey = "visa_list_cache";

  final TextEditingController _controller = TextEditingController();

  List<VisaModel> suggestions = [];
  List<VisaModel> allVisas = [];

  bool loading = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadVisaList();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadVisaList() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() => loading = true);

    try {
      final cached = prefs.getString(_visaCacheKey);

      if (cached != null) {
        final cachedJson = jsonDecode(cached);

        if (cachedJson['success'] == true) {
          final List data = cachedJson['data']['data'];

          allVisas =
              data.map<VisaModel>((e) => VisaModel.fromJson(e)).toList();

          if (!mounted) return;

          setState(() => loading = false);

          return;
        }
      }
    } catch (e) {
      debugPrint("Cache error: $e");
    }

    try {
      final res = await ApiService.getVisaList(limit: 160);

      await prefs.setString(_visaCacheKey, jsonEncode(res));

      if (res['success'] == true) {
        final List data = res['data']['data'];

        allVisas =
            data.map<VisaModel>((e) => VisaModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint("API error: $e");
    }

    if (!mounted) return;

    setState(() => loading = false);
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    final query = value.trim();

    if (query.isEmpty) {
      setState(() => suggestions = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 100), () {
      _searchSuggestions(query);
    });
  }

  void _searchSuggestions(String query) {
    final q = query.toLowerCase();

    final results =
        allVisas
            .where((e) {
              return e.label.toLowerCase().contains(q) ||
                  e.subclass.toLowerCase().contains(q);
            })
            .take(6)
            .toList();

    setState(() {
      suggestions = results;
    });
  }

  Future<void> _navigateToEstimate(VisaModel item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VisaEstimateScreen(visa: item)),
    );

    _controller.clear();

    setState(() {
      suggestions = [];
    });
  }

  static const Color _navy = ThemeConfig.navyBlue;
  static const Color _gold = ThemeConfig.goldenYellow;
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CommonAppBar(
        titleName: "VAC Search",
        matterID: AuthService.selectedMatterId,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppResponsive.maxContentWidth,
            ),
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                setState(() => suggestions = []);
              },
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
                    else
                      Expanded(child: _emptyState()),
                  ],
                ),
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
        onChanged: (v) {
          _onSearchChanged(v);
          setState(() {});
        },
        style: const TextStyle(fontSize: 14.5, color: _textPrimary),
        decoration: InputDecoration(
          hintText: "Search visa or subclass",
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
                      setState(() => suggestions = []);
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
              Icons.badge_outlined,
              size: 34,
              color: _gold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Search for a visa',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Type a visa name or subclass number\nto estimate the visa application charge.',
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
              _controller.text = item.label;
              FocusScope.of(context).unfocus();
              setState(() => suggestions = []);
              _navigateToEstimate(item);
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
                      item.label,
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
                      item.subclass,
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
}
