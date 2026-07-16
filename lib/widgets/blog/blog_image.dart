import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Shows a blog cover image, falling back to a branded local asset when the
/// blog has no real image, uses the CRM's generic "default_blog" placeholder,
/// or the network image fails to load.
///
/// Images are cached to disk via [CachedNetworkImage], so a blog cover is
/// downloaded once and then served instantly (no re-loading spinner) on every
/// later visit.
class BlogImage extends StatelessWidget {
  final String url;
  final double? iconSize;

  const BlogImage({super.key, required this.url, this.iconSize});

  static const String _fallbackAsset = 'assets/images/blog_placeholder.png';

  bool get _hasRealImage {
    if (url.trim().isEmpty) return false;
    return !url.toLowerCase().contains('default_blog');
  }

  Widget get _fallback => Image.asset(_fallbackAsset, fit: BoxFit.cover);

  Widget _placeholder() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E1464), Color(0xFF2D3B8F)],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (!_hasRealImage) return _fallback;
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (ctx, _) => _placeholder(),
      errorWidget: (ctx, _, _) => _fallback,
    );
  }
}
