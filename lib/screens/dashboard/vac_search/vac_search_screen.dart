import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
                    _searchField(),

                    if (suggestions.isNotEmpty) _dropdown(),

                    if (loading)
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Center(child: AppLoader()),
                      ),
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
    return TextField(
      controller: _controller,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: "Search visa or subclass...",
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _controller.clear();

            setState(() => suggestions = []);
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _dropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: suggestions.length,
        itemBuilder: (_, i) {
          final item = suggestions[i];

          return ListTile(
            title: Text(item.label),
            subtitle: Text("Subclass ${item.subclass}"),
            onTap: () {
              _controller.text = item.label;

              FocusScope.of(context).unfocus();

              setState(() => suggestions = []);

              _navigateToEstimate(item);
            },
          );
        },
      ),
    );
  }
}
