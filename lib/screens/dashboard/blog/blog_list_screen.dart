import 'package:client/utils/app_loader.dart';
import 'package:flutter/material.dart';

import '../../../config/theme_config.dart';
import '../../../models/blog.dart';
import '../../../services/api_service_bansal_immigration.dart';
import '../../../utils/cache_helper.dart';
import '../../../utils/responsive_utils.dart';
import '../../../widgets/blog/blog_image.dart';

class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});

  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  static const String _cacheKey = 'blog_list_page1_v1';

  List<Blog> _blogs = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasNextPage = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initBlogs();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoading && _hasNextPage) _fetchBlogs();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Show cached first page instantly, then refresh from network.
  Future<void> _initBlogs() async {
    final cached = await CacheHelper.loadEnvelope(
      _cacheKey,
      maxAge: const Duration(hours: 6),
    );
    if (cached is List && cached.isNotEmpty && mounted) {
      setState(() {
        _blogs = cached
            .map<Blog>((e) => Blog.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      });
    }
    await _refreshFirstPage();
  }

  // Fetches page 1, replaces the list and updates the cache.
  Future<void> _refreshFirstPage() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await ApiServiceBansalImmigration.getBlogs(
        page: 1,
        perPage: 10,
      ).timeout(const Duration(seconds: 30));

      if (response['success'] == true) {
        final List list = response['data'] ?? [];
        final blogs = list.map((e) => Blog.fromJson(e)).toList();
        final pagination = response['pagination'] ?? {};

        if (!mounted) return;
        setState(() {
          _blogs = blogs;
          _hasNextPage = pagination['has_more_pages'] ?? false;
          _currentPage = 2;
        });

        await CacheHelper.saveEnvelope(
          key: _cacheKey,
          data: blogs.map((b) => b.toJson()).toList(),
        );
      }
    } catch (e) {
      debugPrint('Error fetching blogs: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  // Appends the next page for infinite scroll.
  Future<void> _fetchBlogs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await ApiServiceBansalImmigration.getBlogs(
        page: _currentPage,
        perPage: 10,
      ).timeout(const Duration(seconds: 30));

      if (response['success'] == true) {
        final List list = response['data'] ?? [];
        final blogs = list.map((e) => Blog.fromJson(e)).toList();
        final pagination = response['pagination'] ?? {};

        if (!mounted) return;
        setState(() {
          _blogs.addAll(blogs);
          _hasNextPage = pagination['has_more_pages'] ?? false;
          _currentPage++;
        });
      }
    } catch (e) {
      debugPrint('Error fetching blogs: $e');
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;
    setState(() {
      _currentPage = 1;
      _hasNextPage = true;
    });
    await _refreshFirstPage();
  }

  void _openDetail(int blogId) =>
      Navigator.pushNamed(context, '/blogs/detail', arguments: {'blogId': blogId});

  // ── Featured / first card — tall with image-overlay title ─────────────
  Widget _buildFeaturedCard(Blog blog) {
    return GestureDetector(
      onTap: () => _openDetail(blog.id),
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            BlogImage(url: blog.image),

            // Gradient overlay — bottom heavy for text legibility
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.40, 1.0],
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.30),
                    Colors.black.withValues(alpha: 0.88),
                  ],
                ),
              ),
            ),

            // Content overlaid at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (blog.featured)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: ThemeConfig.goldenYellow,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'FEATURED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    Text(
                      blog.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 11, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          blog.date,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.person_rounded,
                            size: 11, color: Colors.white70),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            blog.author.isNotEmpty ? blog.author : 'Bansal Immigration',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Read',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(Icons.arrow_forward_rounded,
                                  size: 10, color: Colors.white),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Standard card — clean horizontal layout ───────────────────────────
  Widget _buildStandardCard(Blog blog) {
    return GestureDetector(
      onTap: () => _openDetail(blog.id),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            SizedBox(
              width: 106,
              height: 106,
              child: BlogImage(url: blog.image),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      blog.date,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      blog.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        height: 1.35,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            blog.author.isNotEmpty ? blog.author : 'Bansal Immigration',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: Color(0xFFF9B000),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.article_outlined, size: 34, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          const Text(
            'No articles yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Text(
            'Pull down to refresh',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.of(context).size.height -
        kToolbarHeight -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: ThemeConfig.goldenYellow,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 4,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Blogs & News',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Stay informed & updated',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _blogs.isEmpty && _isLoading
            ? SizedBox(height: viewportHeight, child: const Center(child: AppLoader()))
            : RefreshIndicator(
                onRefresh: _onRefresh,
                color: ThemeConfig.goldenYellow,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = AppResponsive.gridColumns(
                      context,
                      mobile: 1,
                      tablet: 2,
                      desktop: 3,
                    );

                    // ── Mobile single-column ─────────────────────────────
                    if (cols == 1) {
                      if (_blogs.isEmpty && !_isLoading) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(height: viewportHeight, child: _buildEmptyState()),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        itemCount: _blogs.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Loading spinner at end
                          if (index >= _blogs.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: AppLoader()),
                            );
                          }

                          final blog = _blogs[index];

                          return Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: AppResponsive.maxContentWidth),
                              child: Padding(
                                padding: EdgeInsets.only(bottom: index == 0 ? 14 : 10),
                                child: index == 0
                                    ? _buildFeaturedCard(blog)
                                    : _buildStandardCard(blog),
                              ),
                            ),
                          );
                        },
                      );
                    }

                    // ── Tablet / desktop grid ────────────────────────────
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: AppResponsive.maxContentWidth),
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: AppResponsive.pagePadding(context),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _blogs.length + (_isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < _blogs.length) return _buildFeaturedCard(_blogs[index]);
                            return const Center(child: AppLoader());
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
