import 'package:cached_network_image/cached_network_image.dart';
import 'package:client/utils/app_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../config/theme_config.dart';
import '../../../services/api_service_bansal_immigration.dart';
import '../../../utils/cache_helper.dart';
import '../../../widgets/blog/blog_image.dart';

class BlogDetailScreen extends StatefulWidget {
  final int blogId;

  const BlogDetailScreen({super.key, required this.blogId});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  Map<String, dynamic>? blog;
  bool isLoading = true;

  // ValueNotifier avoids full-widget setState on every scroll frame
  final ValueNotifier<double> _readProgress = ValueNotifier(0.0);
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
    _readProgress.value =
        (_scrollController.position.pixels / max).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _readProgress.dispose();
    super.dispose();
  }

  String get _cacheKey => 'blog_detail_${widget.blogId}_v1';

  Future<void> _fetchBlogDetail() async {
    if (!mounted) return;

    // Show cached article instantly if available (stale-while-revalidate).
    final cached = await CacheHelper.loadEnvelope(
      _cacheKey,
      maxAge: const Duration(hours: 24),
    );
    if (cached is Map && mounted) {
      setState(() {
        blog = Map<String, dynamic>.from(cached);
        isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        isLoading = true;
        blog = null;
      });
    }

    Map<String, dynamic>? loaded;
    try {
      final response = await ApiServiceBansalImmigration.getBlogDetail(
        blogId: widget.blogId,
      ).timeout(const Duration(seconds: 30));
      if (response['success'] == true) loaded = response['data'];
    } catch (e) {
      debugPrint('Error fetching blog: $e');
    }

    if (loaded != null) {
      await CacheHelper.saveEnvelope(key: _cacheKey, data: loaded);
    }

    if (!mounted) return;
    setState(() {
      if (loaded != null) blog = loaded;
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _appBar(),
        body: const Center(child: AppLoader()),
      );
    }

    if (blog == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: _appBar(),
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(title: blog!['title']),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            slivers: [
              // ── Hero image ───────────────────────────────────────────────
              SliverToBoxAdapter(child: _buildHero()),

              // ── Meta bar ─────────────────────────────────────────────────
              SliverToBoxAdapter(child: _buildMeta()),

              // ── Divider ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(height: 1, color: const Color(0xFFF1F5F9)),
              ),

              // ── Article HTML body ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Html(
                    data: blog!['description'] ?? '',
                    extensions: [
                      // Cache in-article images to disk so they load once and
                      // then appear instantly on every later visit.
                      TagExtension(
                        tagsToExtend: {'img'},
                        builder: (ctx) {
                          final src = ctx.attributes['src'] ?? '';
                          if (src.trim().isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: CachedNetworkImage(
                                imageUrl: src,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                fadeInDuration:
                                    const Duration(milliseconds: 200),
                                placeholder: (c, _) => Container(
                                  height: 180,
                                  color: const Color(0xFFF1F5F9),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          ThemeConfig.goldenYellow,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (c, _, _) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
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
                        fontSize: FontSize(22),
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        margin: Margins.only(bottom: 12, top: 28),
                        lineHeight: LineHeight(1.25),
                      ),
                      'h2': Style(
                        fontSize: FontSize(19),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        margin: Margins.only(bottom: 10, top: 24),
                        lineHeight: LineHeight(1.3),
                      ),
                      'h3': Style(
                        fontSize: FontSize(16),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                        margin: Margins.only(bottom: 8, top: 20),
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
                      'ul': Style(margin: Margins.only(bottom: 18, left: 4)),
                      'ol': Style(margin: Margins.only(bottom: 18, left: 4)),
                      'li': Style(
                        fontSize: FontSize(15.5),
                        color: const Color(0xFF374151),
                        lineHeight: LineHeight(1.8),
                        margin: Margins.only(bottom: 6),
                      ),
                      'blockquote': Style(
                        border: const Border(
                          left:
                              BorderSide(color: Color(0xFFF9B000), width: 3),
                        ),
                        padding: HtmlPaddings.only(left: 16),
                        color: const Color(0xFF64748B),
                        fontStyle: FontStyle.italic,
                        margin: Margins.only(bottom: 20, top: 4, left: 0),
                        backgroundColor: const Color(0xFFFFFBEB),
                      ),
                      'img': Style(
                        width: Width(double.infinity),
                        margin: Margins.only(bottom: 18),
                      ),
                    },
                  ),
                ),
              ),

              // ── End marker ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: Colors.grey.shade200, thickness: 1)),
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
                                  color: Colors.grey.shade200, thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'You\'ve reached the end',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Reading progress bar (no setState — ValueNotifier only) ──────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<double>(
              valueListenable: _readProgress,
              builder: (_, value, _) => SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                  value: value,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      ThemeConfig.goldenYellow),
                  minHeight: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _appBar({String? title}) {
    return AppBar(
      backgroundColor: ThemeConfig.goldenYellow,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      title: title != null
          ? Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.white),
          tooltip: 'Copy link',
          onPressed: blog != null ? _copyLink : null,
        ),
      ],
    );
  }

  Widget _buildHero() {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          BlogImage(url: (blog!['image'] ?? '').toString()),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 0.75, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.10),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.50),
                  Colors.black.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (blog!['featured'] == true)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ThemeConfig.goldenYellow,
                          borderRadius: BorderRadius.circular(5),
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
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
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
    );
  }

  Widget _buildMeta() {
    final author = blog!['author']?.toString().isNotEmpty == true
        ? blog!['author'].toString()
        : 'Bansal Immigration';
    final date = blog!['date']?.toString() ?? '';
    final readingTime = blog!['reading_time'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1464), Color(0xFF2D3B8F)],
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(author),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  author,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (date.isNotEmpty)
                      _metaChip(Icons.calendar_today_rounded, date),
                    if (date.isNotEmpty && readingTime != null)
                      const SizedBox(width: 8),
                    if (readingTime != null)
                      _metaChip(Icons.timer_outlined, '$readingTime min read'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'B';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
