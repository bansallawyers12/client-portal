import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../config/theme_config.dart';
import '../../utils/app_loader.dart';

class UniversalWebView extends StatefulWidget {
  final String url;
  final String viewId;
  final String title;

  const UniversalWebView({
    super.key,
    required this.url,
    required this.viewId,
    this.title = "Health Insurance",
  });

  @override
  State<UniversalWebView> createState() => _UniversalWebViewState();
}

class _UniversalWebViewState extends State<UniversalWebView>
    with SingleTickerProviderStateMixin {
  // Keeps loaded controllers alive across navigations so revisiting a link
  // reuses the already-rendered page instead of reloading from scratch.
  static final Map<String, _CachedWebView> _webViewCache = {};

  late final WebViewController _controller;

  bool _isLoading = true;
  bool _hasError = false;

  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  String get _host {
    try {
      return Uri.parse(widget.url).host;
    } catch (_) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    )..addListener(() {
      setState(() {});
    });

    if (!kIsWeb) {
      final cached = _webViewCache[widget.url];

      if (cached != null) {
        // Reuse the previously loaded controller — no reload, no loader.
        _controller = cached.controller;
        _isLoading = !cached.loaded;
        _attachDelegate();
      } else {
        _controller = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted);

        // ❗ FIX: macOS crash (DO NOT call setBackgroundColor on macOS)
        if (!Platform.isMacOS) {
          _controller.setBackgroundColor(const Color(0xFFFFFFFF));
        }

        _attachDelegate();
        _controller.loadRequest(Uri.parse(widget.url));
        _webViewCache[widget.url] = _CachedWebView(_controller);
      }
    }
  }

  void _attachDelegate() {
    _controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (int progress) {
          _updateProgress(progress);
        },
        onPageStarted: (_) {
          _updateProgress(0);
          if (mounted) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          }
        },
        onPageFinished: (_) {
          _updateProgress(100);
          _webViewCache[widget.url]?.loaded = true;
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted) setState(() => _isLoading = false);
          });
        },
        onWebResourceError: (error) {
          // Only surface errors for the main document, not sub-resources.
          if ((error.isForMainFrame ?? true) && mounted) {
            _webViewCache[widget.url]?.loaded = false;
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          }
        },
      ),
    );
  }

  Future<void> _reload() async {
    _webViewCache[widget.url]?.loaded = false;
    if (mounted) {
      setState(() {
        _hasError = false;
        _isLoading = true;
      });
    }
    _updateProgress(0);
    await _controller.reload();
  }

  Future<void> _openExternally() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

  PreferredSizeWidget _appBar(double progress) {
    return AppBar(
      backgroundColor: ThemeConfig.goldenYellow,
      foregroundColor: Colors.white,
      elevation: 2,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (_host.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.lock_rounded, size: 10, color: Colors.white70),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _host,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Reload',
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _reload,
        ),
        IconButton(
          tooltip: 'Open in browser',
          icon: const Icon(Icons.open_in_new_rounded),
          onPressed: _openExternally,
        ),
      ],
      bottom: _isLoading
          ? PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: LinearProgressIndicator(
                value: progress == 0 ? null : progress,
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  ThemeConfig.navyBlue,
                ),
              ),
            )
          : null,
    );
  }

  Widget _errorView() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 52,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Couldn't load this page",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: ThemeConfig.navyBlue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Please check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeConfig.navyBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _reload,
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _openExternally,
                child: const Text('Open in browser instead'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateProgress(int newProgress) {
    final newValue = (newProgress.clamp(0, 100)) / 100;

    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: newValue,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward(from: 0);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double smoothValue = _progressAnimation.value;

    if (kIsWeb) {
      return Scaffold(
        appBar: _appBar(smoothValue),
        body: _WebFallbackView(url: widget.url, title: widget.title),
      );
    }

    final double scale = 0.85 + (smoothValue * 0.35);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(smoothValue),
      body: Stack(
        children: [
          Positioned.fill(
            child: WebViewWidget(controller: _controller),
          ),

          if (_hasError)
            Positioned.fill(child: _errorView())
          else if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white,
                child: Center(
                  child: Platform.isMacOS
                      ? _buildMacOSLoader(scale, smoothValue)
                      : AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: _buildLoader(scale, smoothValue),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoader(double scale, double smoothValue) {
    return Transform.scale(
      scale: scale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 110,
            width: 110,
            child: AppLoader(),
          ),
          Image.asset(
            'assets/icons/app_icon.png',
            height: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildMacOSLoader(double scale, double smoothValue) {
    return Transform.scale(
      scale: scale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 110,
            width: 110,
            child: CircularProgressIndicator(
              value: smoothValue,
              strokeWidth: 4,
              color: ThemeConfig.successColor,
              backgroundColor: Colors.grey.shade200,
            ),
          ),
          Image.asset(
            'assets/icons/app_icon.png',
            height: 40,
          ),
        ],
      ),
    );
  }
}

class _CachedWebView {
  final WebViewController controller;
  bool loaded = false;

  _CachedWebView(this.controller);
}

class _WebFallbackView extends StatefulWidget {
  final String url;
  final String title;

  const _WebFallbackView({required this.url, required this.title});

  @override
  State<_WebFallbackView> createState() => _WebFallbackViewState();
}

class _WebFallbackViewState extends State<_WebFallbackView> {
  bool _launching = false;

  Future<void> _openInBrowser() async {
    setState(() => _launching = true);
    try {
      final uri = Uri.parse(widget.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open the link.')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeConfig.successColor.withValues(alpha:0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.open_in_browser_rounded,
                size: 56,
                color: ThemeConfig.successColor,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'This page needs to open in your browser.\nYour session and data will be kept secure.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _launching
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.launch_rounded),
                label: Text(_launching ? 'Opening...' : 'Open in Browser'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeConfig.successColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _launching ? null : _openInBrowser,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Go Back',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}