import 'package:flutter/material.dart';

/// Shows a blog cover image, falling back to a branded local asset when the
/// blog has no real image, uses the CRM's generic "default_blog" placeholder,
/// or the network image fails to load.
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
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (ctx, child, progress) =>
          progress == null ? child : _placeholder(),
      errorBuilder: (ctx, err, stack) => _fallback,
    );
  }
}
