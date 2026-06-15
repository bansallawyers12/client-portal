import 'dart:async';
import 'dart:convert';

import 'package:client/services/api_service_bansal_immigration.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/post_code_checker/postcode_result.dart';
import '../../../models/post_code_checker/postcode_search_item.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_loader.dart';
import '../../../utils/responsive_utils.dart';
import '../../../widgets/common_app_bar.dart';

class PostcodeCheckerScreen extends StatefulWidget {
  const PostcodeCheckerScreen({super.key});

  @override
  State<PostcodeCheckerScreen> createState() => _PostcodeCheckerScreenState();
}

class _PostcodeCheckerScreenState extends State<PostcodeCheckerScreen> {
  static const String _postcodeCacheKey = "postcode_all_cache";

  static const _primary = Color(0xFF1A56DB);
  static const _accent = Color(0xFF0E9F6E);
  static const _accentLight = Color(0xFFECFDF5);
  static const _border = Color(0xFFE5E7EB);
  static const _textPrimary = Color(0xFF111827);
  static const _textSecondary = Color(0xFF6B7280);
  static const _bg = Color(0xFFF9FAFB);

  final TextEditingController _controller = TextEditingController();

  Timer? _debounce;

  List<PostcodeSearchItem> allPostcodes = [];
  List<PostcodeSearchItem> suggestions = [];
  PostcodeResult? result;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadPostcodes();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPostcodes() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() => loading = true);

    try {
      final cached = prefs.getString(_postcodeCacheKey);

      if (cached != null) {
        final decoded = jsonDecode(cached);

        allPostcodes = (decoded as List)
            .map((e) => PostcodeSearchItem.fromJson(e))
            .toList();

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
      final response = await ApiServiceBansalImmigration.postcodeAll();

      if (response['success'] == true) {
        allPostcodes = (response['data'] as List)
            .map((e) => PostcodeSearchItem.fromJson(e))
            .toList();

        await prefs.setString(
          _postcodeCacheKey,
          jsonEncode(response['data']),
        );
      }
    } catch (e) {
      debugPrint("API error: $e");
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) {
      setState(() => suggestions = []);
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 100),
      () => _searchSuggestions(query),
    );
  }

  void _searchSuggestions(String query) {
    final q = query.toLowerCase();
    final results =
        allPostcodes
            .where(
              (e) =>
                  e.suburb.toLowerCase().contains(q) ||
                  e.postcode.toLowerCase().contains(q) ||
                  e.state.toLowerCase().contains(q),
            )
            .take(8)
            .toList();
    if (mounted) setState(() => suggestions = results);
  }

  Future<void> _fetchResult(String postcode) async {
    setState(() {
      loading = true;
      suggestions.clear();
      result = null;
    });
    try {
      final response = await ApiServiceBansalImmigration.postcodeResult(postcode);
      if (response['success']) {
        setState(() {
          result = PostcodeResult.fromJson(response['data']);
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      debugPrint("Result error: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: CommonAppBar(
        titleName: 'Postcode Checker Tool',
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
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: AppResponsive.pagePadding(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildSearchField(),
                    if (suggestions.isNotEmpty) _buildSuggestions(),
                    const SizedBox(height: 12),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: AppLoader()),
                      ),
                    if (result != null) _buildResultCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on_rounded, color: _primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Australian Postcode Checker',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Check if your postcode qualifies for regional area points for skilled migration visas.',
          style: TextStyle(fontSize: 13.5, color: _textSecondary, height: 1.5),
        ),
        const SizedBox(height: 16),
        const Divider(color: _border),
      ],
    );
  }

  Widget _buildSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter Postcode or Suburb',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          onChanged: _onSearchChanged,
          style: const TextStyle(fontSize: 14, color: _textPrimary),
          decoration: InputDecoration(
            hintText: 'e.g. Sydney or 2000',
            hintStyle: const TextStyle(color: _textSecondary, fontSize: 14),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: _primary,
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.close_rounded,
                color: _textSecondary,
                size: 18,
              ),
              onPressed: () {
                _controller.clear();
                setState(() {
                  suggestions = [];
                  result = null;
                });
              },
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: suggestions.length,
          separatorBuilder:
              (_, _) => const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: _border,
              ),
          itemBuilder: (_, i) {
            final item = suggestions[i];
            return InkWell(
              onTap: () {
                _controller.text = item.suburb;
                FocusScope.of(context).unfocus();
                setState(() => suggestions = []);
                _fetchResult(item.postcode);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: _primary,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${item.suburb}  ·  ${item.postcode}, ${item.state}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: _textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: _textSecondary,
                      size: 17,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: _accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Result',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 4),
          _resultRow('Postcode', result!.postcode),
          _resultRow('Area', result!.area),
          _resultRow('State', result!.state),
          _resultRow(
            'Regional Status',
            result!.regionalStatus,
            highlight: true,
          ),
          _resultRow('Category', result!.category, last: true),
        ],
      ),
    );
  }

  Widget _resultRow(
    String label,
    String value, {
    bool highlight = false,
    bool last = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              SizedBox(
                width: 130,
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: _textSecondary),
                ),
              ),
              Expanded(
                child:
                    highlight
                        ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _accentLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _accent,
                            ),
                          ),
                        )
                        : Text(
                          value,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
              ),
            ],
          ),
        ),
        if (!last) const Divider(height: 1, color: _border),
      ],
    );
  }
}
