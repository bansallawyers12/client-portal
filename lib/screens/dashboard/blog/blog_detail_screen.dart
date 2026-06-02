import 'package:client/utils/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../config/theme_config.dart';
import '../../../services/api_service.dart';
import '../../../utils/responsive_utils.dart';

class BlogDetailScreen extends StatefulWidget {
  final int blogId;

  const BlogDetailScreen({super.key, required this.blogId});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  Map<String, dynamic>? blog;
  bool isLoading = true;
  double _readProgress = 0.0;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _fetchBlogDetail();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (max <= 0) return;
    final progress =
        (_scrollController.position.pixels / max).clamp(0.0, 1.0);
    if ((progress - _readProgress).abs() > 0.004) {
      setState(() => _readProgress = progress);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchBlogDetail() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      blog = null;
    });

    Map<String, dynamic>? loaded;
    try {
      final response = await ApiService.getBlogDetail(blogId: widget.blogId)
          .timeout(const Duration(seconds: 30));
      if (response['success'] == true) loaded = response['data'];
    } catch (e) {
      debugPrint('Error fetching blog: $e');
    }

    if (!mounted) return;
    setState(() {
      blog = loaded;
      isLoading = false;
    });
  }

  void _copyLink() {
    final url = blog?['url']?.toString() ?? '';
    if (url.isEmpty) return;
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Link copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E1464),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Loading state ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: ThemeConfig.goldenYellow,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: AppLoader()),
      );
    }

    // ── Error / not found ────────────────────────────────────────────────
    if (blog == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          backgroundColor: ThemeConfig.goldenYellow,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(Icons.article_outlined,
                    size: 40, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 20),
              const Text(
                'Article not found',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'This article may have been removed.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      );
    }

    // ── Main article screen ──────────────────────────────────────────────
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // ── Hero AppBar ────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 340,
                pinned: true,
                stretch: true,
                backgroundColor: ThemeConfig.goldenYellow,
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white),
                    tooltip: 'Copy link',
                    onPressed: _copyLink,
                  ),
                ],
                title: Text(
                  blog!['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  collapseMode: CollapseMode.parallax,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Hero image
                      Image.network(
                        blog!['image'] ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, st) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1E1464),
                                Color(0xFF3949AB),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.article_outlined,
                                size: 64, color: Colors.white12),
                          ),
                        ),
                      ),

                      // Layered gradient: transparent top → dark bottom
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.35, 0.65, 1.0],
                            colors: [
                              Colors.black.withValues(alpha: 0.20),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.45),
                              Colors.black.withValues(alpha: 0.90),
                            ],
                          ),
                        ),
                      ),

                      // Title + meta overlaid at bottom
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (blog!['featured'] == true)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: ThemeConfig.goldenYellow,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'FEATURED',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              Text(
                                blog!['title'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Golden accent line at very bottom
                      const Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: SizedBox(
                          height: 3,
                          child: ColoredBox(color: ThemeConfig.goldenYellow),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Meta bar ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1464).withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_rounded,
                            size: 18, color: Color(0xFF1E1464)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              blog!['author']?.toString().isNotEmpty == true
                                  ? blog!['author']
                                  : 'Bansal Immigration',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Text(
                                  blog!['date']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                if (blog!['reading_time'] != null) ...[
                                  const Text(
                                    '  ·  ',
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF94A3B8)),
                                  ),
                                  Text(
                                    '${blog!['reading_time']} min read',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Thin spacer between meta and content
              const SliverToBoxAdapter(
                child: SizedBox(height: 8),
              ),

              // ── Article body ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: SafeArea(
                  top: false,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                          maxWidth: AppResponsive.maxContentWidth),
                      child: Container(
                        color: Colors.white,
                        padding: AppResponsive.horizontalPadding(context)
                            .copyWith(top: 22, bottom: 0),
                        child: Html(
                          data: blog!['description'] ?? '',
                          style: {
                            'body': Style(
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                            ),
                            'p': Style(
                              fontSize: FontSize(15.5),
                              color: const Color(0xFF374151),
                              margin: Margins.only(bottom: 18),
                              lineHeight: LineHeight(1.8),
                            ),
                            'h1': Style(
                              fontSize: FontSize(24),
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                              margin: Margins.only(bottom: 14, top: 32),
                              lineHeight: LineHeight(1.25),
                            ),
                            'h2': Style(
                              fontSize: FontSize(20),
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                              margin: Margins.only(bottom: 12, top: 28),
                              lineHeight: LineHeight(1.3),
                            ),
                            'h3': Style(
                              fontSize: FontSize(17),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                              margin: Margins.only(bottom: 10, top: 22),
                            ),
                            'strong': Style(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            'em': Style(
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF475569),
                            ),
                            'a': Style(
                              color: const Color(0xFFF9B000),
                              textDecorationColor: const Color(0xFFF9B000),
                            ),
                            'ul': Style(
                                margin: Margins.only(bottom: 18, left: 4)),
                            'ol': Style(
                                margin: Margins.only(bottom: 18, left: 4)),
                            'li': Style(
                              fontSize: FontSize(15.5),
                              color: const Color(0xFF374151),
                              lineHeight: LineHeight(1.8),
                              margin: Margins.only(bottom: 6),
                            ),
                            'blockquote': Style(
                              border: const Border(
                                left: BorderSide(
                                    color: Color(0xFFF9B000), width: 3),
                              ),
                              padding: HtmlPaddings.only(left: 16),
                              color: const Color(0xFF64748B),
                              fontStyle: FontStyle.italic,
                              margin:
                                  Margins.only(bottom: 20, top: 4, left: 0),
                              backgroundColor:
                                  const Color(0xFFFFFBEB),
                            ),
                            'img': Style(
                              width: Width(double.infinity),
                              margin: Margins.only(bottom: 18),
                            ),
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── End of article footer ────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(18, 32, 18, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                                color: Colors.grey.shade200, thickness: 1),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: ThemeConfig.goldenYellow,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.star_rounded,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                                color: Colors.grey.shade200, thickness: 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'You\'ve reached the end',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Back button ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 48),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back_rounded,
                              size: 16, color: Color(0xFF334155)),
                          SizedBox(width: 8),
                          Text(
                            'Back to Blogs',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Reading progress bar (always on top) ─────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: _readProgress,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  ThemeConfig.goldenYellow,
                ),
                minHeight: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
