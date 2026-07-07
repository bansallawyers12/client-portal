import 'package:client/config/theme_config.dart'; // ✅ Import theme
import 'package:flutter/material.dart';

import '../../models/new/document_category.dart';
import '../../services/api_service.dart';
import '../../utils/app_loader.dart';
import '../../utils/cache_helper.dart';
import '../../utils/responsive_utils.dart';

class DocumentManagementScreen extends StatefulWidget {
  const DocumentManagementScreen({super.key});

  @override
  State<DocumentManagementScreen> createState() =>
      _DocumentManagementScreenState();
}

class _DocumentManagementScreenState extends State<DocumentManagementScreen>
    with TickerProviderStateMixin {
  late TabController _mainTabController;

  List<DocumentCategory> _categories = [];
  List<DocumentChecklist> _documents = [];

  bool _isLoading = false;
  String? _errorMessage;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _loadCategories("personal");
  }

  Future<void> _loadCategories(String type) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Categories are reference data — seed from cache for instant display.
    final cachedCats = await CacheHelper.loadData<DocumentCategory>(
      'doc_categories_${type}_v1',
      (json) => DocumentCategory.fromJson(json),
    );
    if (cachedCats.isNotEmpty && mounted) {
      setState(() {
        _categories = cachedCats;
        _selectedCategoryId = cachedCats.first.id;
      });
    }

    try {
      final response = await ApiService.getDocumentCategories(type: type);
      final cats =
          (response['data']['categories'] as List)
              .map((json) => DocumentCategory.fromJson(json))
              .toList();

      await CacheHelper.saveData(key: 'doc_categories_${type}_v1', data: cats);

      setState(() {
        _categories = cats;
        if (_categories.isNotEmpty) {
          _selectedCategoryId = _categories.first.id;
        }
      });

      await _loadChecklist(type);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load categories: $e";
      });
    }
  }

  Future<void> _loadChecklist(String type) async {
    if (_selectedCategoryId == null) {
      setState(() {
        _documents = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getDocumentChecklist(type: type);
      final docs =
          (response).map((json) => DocumentChecklist.fromJson(json)).toList();

      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Failed to load checklist: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentType = _mainTabController.index == 0 ? "personal" : "visa";

    return Scaffold(
      backgroundColor: ThemeConfig.navyBlue, // ✅ Background color
      appBar: AppBar(
        title: const Text("Documents"),
        backgroundColor: ThemeConfig.goldenYellow, // ✅ AppBar theme
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _mainTabController,
          indicatorColor: Colors.white,
          onTap: (index) {
            final type = index == 0 ? "personal" : "visa";
            _loadCategories(type);
          },
          tabs: const [
            Tab(text: "Personal Documents"),
            Tab(text: "Visa Documents"),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppResponsive.maxContentWidth,
            ),
            child: Column(
              children: [
                if (_categories.isNotEmpty)
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final selected = cat.id == _selectedCategoryId;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = cat.id;
                            });
                            _loadChecklist(currentType);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 10,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  selected
                                      ? ThemeConfig.goldenYellow
                                      : Colors.grey[700],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                cat.title,
                                style: TextStyle(
                                  color:
                                      selected ? Colors.white : Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                Expanded(child: _buildBody(currentType)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(String type) {
    if (_isLoading) return const Center(child: AppLoader());
    if (_errorMessage != null) return _buildError(type);
    if (_documents.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      onRefresh: () async => _loadChecklist(type),
      color: ThemeConfig.goldenYellow,
      child: ListView.builder(
        itemCount: _documents.length,
        itemBuilder: (context, index) {
          final doc = _documents[index];
          return Card(
            color: Colors.grey[800], // ✅ Card background
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(
                doc.name,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Type: ${doc.docTypeName}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    "Created: ${doc.createdAt}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    "Updated: ${doc.updatedAt}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.goldenYellow,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  // TODO: Upload / View
                },
                child: const Text("Action"),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConfig.goldenYellow,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _loadCategories(type),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.folder_open, size: 64, color: Colors.white70),
          SizedBox(height: 16),
          Text("No documents found", style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
