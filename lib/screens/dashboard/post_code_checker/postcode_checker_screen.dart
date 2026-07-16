import 'dart:async';
import 'dart:convert';

import 'package:client/services/api_service_bansal_immigration.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/theme_config.dart';
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

  static const _primary = ThemeConfig.navyBlue;
  static const _gold = ThemeConfig.goldenYellow;
  static const _accent = Color(0xFF0E9F6E);
  static const _accentLight = Color(0xFFECFDF5);
  static const _border = Color(0xFFE2E8F0);
  static const _textPrimary = Color(0xFF1F2937);
  static const _textSecondary = Color(0xFF64748B);
  static const _bg = Color(0xFFF5F7FA);

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
        final fetched = PostcodeResult.fromJson(response['data']);
        setState(() {
          result = fetched;
          loading = false;
        });
        if (mounted) _showResultDialog(fetched);
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
        child: Align(
          alignment: Alignment.topCenter,
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: _gold,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Australian Postcode Checker',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: _primary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
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
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
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
              hintText: 'e.g. Sydney or 2000',
              hintStyle: const TextStyle(color: _textSecondary, fontSize: 14),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: _textSecondary,
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
                vertical: 15,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _primary, width: 1.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _border),
              ),
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

  void _showResultDialog(PostcodeResult data) {
    final isRegional = data.regionalStatus.toLowerCase().contains('yes');
    final statusColor = isRegional ? _accent : const Color(0xFFDC2626);
    final statusBg = isRegional ? _accentLight : const Color(0xFFFEF2F2);

    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primary, Color(0xFF3B2E9E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              data.postcode,
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${data.area}, ${data.state}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: _dialogCloseButton(),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isRegional
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                color: statusColor,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Regional Status',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: _textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      data.regionalStatus,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _border),
                          ),
                          child: Column(
                            children: [
                              _dialogDetailRow('Postcode', data.postcode),
                              _dialogDivider(),
                              _dialogDetailRow('Area', data.area),
                              _dialogDivider(),
                              _dialogDetailRow('State', data.state),
                              _dialogDivider(),
                              _dialogDetailRow('Category', data.category),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _dialogCloseButton() {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.pop(context),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _dialogDivider() =>
      Divider(height: 1, thickness: 1, color: _border.withValues(alpha: 0.6));

  Widget _dialogDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: _textSecondary),
            ),
          ),
          Expanded(
            child: Text(
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
    );
  }
}
