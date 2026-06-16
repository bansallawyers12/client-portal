import 'dart:async';
import 'dart:ui';

import 'package:client/services/stripe_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../config/theme_config.dart';
import '../../../fcm_service.dart';
import '../../../models/blog.dart';
import '../../../models/case_summary.dart';
import '../../../models/dashboard_summary.dart';
import '../../../models/recent_activity.dart';
import '../../../services/api_service.dart';
import '../../../services/api_service_bansal_immigration.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_loader.dart';
import '../../../utils/responsive_utils.dart';
import '../../../widgets/common/error_widget.dart';
import '../../../widgets/common/pressable_scale.dart';
import '../../../widgets/dashboard/quick_actions_card.dart';
import '../../../widgets/dialog/login_signup_dialog.dart';
import '../book_appointment/book_location_screen.dart';

class DashboardTabScreen extends StatefulWidget {
  final String? matterId;

  const DashboardTabScreen({super.key, required this.matterId});

  @override
  State<DashboardTabScreen> createState() => _DashboardTabScreenState();
}

class _DashboardTabScreenState extends State<DashboardTabScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  DashboardSummary? _dashboardSummary;
  CaseSummary? _caseSummary;
  List<RecentActivity> _recentActivity = [];

  List<Blog> _blogs = [];
  bool _isLoadingBlogs = false;

  // Auto-scrolling news carousel (infinite loop via modulo indexing)
  PageController _blogController = PageController(viewportFraction: 0.84);
  Timer? _blogTimer;
  int _blogPage = 0;

  String? userName;
  bool isLoadingUser = true;

  // Dark slate → near-black body gradient (matches splash screen)
  static const Color _bgTop = Color(0xFF223344);
  static const Color _bgBottom = Color(0xFF101722);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadRecentBlogs();
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows) {
      _setupNotifications();
    }
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (AuthService.isAuthenticated) {
      final name = await AuthManager.getUserName();
      setState(() {
        userName = name;
        isLoadingUser = false;
      });
    } else {
      setState(() {
        isLoadingUser = false;
      });
    }
  }

  Future<void> _setupNotifications() async {
    final fcmService = FCMService();

    fcmService.setupMessageListeners(
      onForegroundMessage: (RemoteMessage message) {
        if (!mounted) return;
        debugPrint('Got a message whilst in the foreground!');
        if (message.notification != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message.notification!.body ?? 'New notification'),
              backgroundColor: Color(0xFF5E8B7E),
              duration: Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Dismiss',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      },
      onBackgroundMessageTap: (RemoteMessage message) {
        debugPrint(
          'Notification tapped while app in background: ${message.messageId}',
        );
      },
    );

    String? token = await fcmService.getToken();
    if (token != null) {
      await ApiService.registerFCMToken(token);
    }
  }

  Future<void> _loadRecentBlogs() async {
    setState(() => _isLoadingBlogs = true);

    try {
      final response = await ApiServiceBansalImmigration.getBlogs(page: 1, perPage: 5);
      if (response['success'] == true) {
        final List list = response['data'];
        _blogs = list.map((e) => Blog.fromJson(e)).toList();
      }
    } catch (_) {}

    setState(() => _isLoadingBlogs = false);
    _setupBlogCarousel();
  }

  void _setupBlogCarousel() {
    _blogTimer?.cancel();
    if (_blogs.length < 2) return;

    // Start in the middle of a huge virtual range so it can loop forever
    // in both directions; the real blog = page % _blogs.length.
    _blogController.dispose();
    final base = _blogs.length * 1000;
    _blogPage = base;
    _blogController =
        PageController(viewportFraction: 0.84, initialPage: base);

    _blogTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_blogController.hasClients) return;
      _blogPage += 1; // always forward — last wraps to first seamlessly
      _blogController.animateToPage(
        _blogPage,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _blogTimer?.cancel();
    _blogController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (widget.matterId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getDashboard(
        selMatterId: widget.matterId!,
      );

      if (result['success'] == true) {
        final data = result['data'];

        CaseSummary? caseSummary;
        if (data['case_summary'] != null) {
          caseSummary = CaseSummary.fromJson(data['case_summary']);
        }

        DashboardSummary dashboardSummary = DashboardSummary(
          activeCases: data['active_cases'] ?? 0,
          totalDocuments: data['total_documents'] ?? 0,
          totalAppointments: data['total_appointments'] ?? 0,
        );

        List<RecentActivity> recentActivity = [];
        if (data['recent_activity'] != null &&
            data['recent_activity'] is List) {
          recentActivity =
              (data['recent_activity'] as List)
                  .map(
                    (e) =>
                        RecentActivity.fromJson(Map<String, dynamic>.from(e)),
                  )
                  .toList();
        }

        setState(() {
          _dashboardSummary = dashboardSummary;
          _caseSummary = caseSummary;
          _recentActivity = recentActivity;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result['message'] ?? 'Failed to load dashboard';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgTop,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgBottom],
          ),
        ),
        child: SafeArea(
          child:
            _isLoading
                ? const AppLoader()
                : _errorMessage != null
                ? CustomErrorWidget(
                  message: _errorMessage!,
                  onRetry: _loadDashboardData,
                )
                : RefreshIndicator(
                  onRefresh: () async {
                    await Future.wait([
                      _loadDashboardData(),
                      _loadRecentBlogs(),
                    ]);
                  },
                  child: SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppResponsive.maxContentWidth,
                        ),
                        child: Container(
                          color: Colors.transparent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 8),
                              _buildRecentUpdatesSection(),
                              const SizedBox(height: 20),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: AppResponsive.isDesktop(context) ? 32 : 10,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    QuickActionsCard(
                                      onBookAppointment: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const BookLocationScreen(),
                                          ),
                                        );
                                      },
                                      onHealthInsurance: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/health-insurance',
                                        );
                                      },
                                      onUpcomingDeadlines: () {
                                        Navigator.pushNamed(context, '/tasks');
                                      },
                                      onPRCalculator: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/pr-calculator',
                                        );
                                      },
                                      onStudentFundCalculator: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/student-fund-calculator',
                                        );
                                      },
                                      onOccupationSearch: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/occupation-search',
                                        );
                                      },
                                      onPostCodeChecker: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/post-code-checker',
                                        );
                                      },
                                      onImportantLinks:
                                          () => {
                                            Navigator.pushNamed(
                                              context,
                                              '/important-links',
                                            ),
                                          },
                                      onEnglishRequirement:
                                          () => {
                                            Navigator.pushNamed(
                                              context,
                                              '/english-requirements',
                                            ),
                                          },
                                      onVACSearch:
                                          () => {
                                            Navigator.pushNamed(
                                              context,
                                              '/vac-search',
                                            ),
                                          },
                                    ),
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/claude-chat-bot');
        },
        backgroundColor: ThemeConfig.goldenYellow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 6,
        tooltip: 'Claude AI Assistant',
        child: const Icon(Icons.chat, size: 28, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildRecentUpdatesSection() {
    final double cardWidth = AppResponsive.value<double>(
      context,
      mobile: 240,
      tablet: 280,
      desktop: 320,
    );
    final double sectionHeight = AppResponsive.value<double>(
      context,
      mobile: 195,
      tablet: 220,
      desktop: 255,
    );
    final isDesktop = AppResponsive.isDesktop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────────────────
        Padding(
          padding: AppResponsive.horizontalPadding(context)
              .copyWith(top: isDesktop ? 24 : 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Recent Updates",
                    style: TextStyle(
                      fontSize: isDesktop ? 20 : 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Latest immigration news",
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.white.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9B000),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 6,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9B000).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (AuthService.isAuthenticated) {
                    Navigator.pushNamed(context, '/blogs');
                  } else {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      barrierColor: Colors.black.withValues(alpha: 0.4),
                      builder: (ctx) => BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                        child: LoginSignupDialog(
                          parentContext: context,
                          onCancel: () {},
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9B000).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF9B000).withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "View all",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF9B000),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: Color(0xFFF9B000),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Card list ───────────────────────────────────────────────
        SizedBox(
          height: sectionHeight,
          child: _isLoadingBlogs
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  padding: AppResponsive.horizontalPadding(context),
                  itemBuilder: (_, i) => _buildSkeletonCard(cardWidth, i),
                )
              : _blogs.isEmpty
                  ? Center(
                      child: Text(
                        'No updates available',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 14,
                        ),
                      ),
                    )
                  : PageView.builder(
                      controller: _blogController,
                      // null itemCount => infinite; index % length picks the blog
                      itemCount: _blogs.length > 1 ? null : _blogs.length,
                      onPageChanged: (i) => _blogPage = i,
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _blogController,
                          builder: (context, child) {
                            double scale = 1.0;
                            if (_blogController.position.haveDimensions) {
                              final page = _blogController.page ?? 0.0;
                              scale = (1 - ((page - index).abs() * 0.16))
                                  .clamp(0.84, 1.0);
                            } else if (index != _blogController.initialPage) {
                              scale = 0.84;
                            }
                            return Transform.scale(scale: scale, child: child);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _buildBlogCard(
                              _blogs[index % _blogs.length],
                            ),
                          ),
                        );
                      },
                    ),
        ),
        if (_blogs.length > 1) ...[
          const SizedBox(height: 12),
          _buildBlogIndicator(),
        ],
      ],
    );
  }

  Widget _buildBlogIndicator() {
    return Center(
      child: AnimatedBuilder(
        animation: _blogController,
        builder: (context, _) {
          final rawPage = _blogController.hasClients &&
                  _blogController.position.haveDimensions
              ? (_blogController.page ?? 0).round()
              : _blogPage;
          final current = rawPage % _blogs.length;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_blogs.length, (i) {
              final active = i == current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFF9B000)
                      : Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildBlogCard(Blog blog) {
    const double stripHeight = 64.0;

    void handleTap() {
      if (AuthService.isAuthenticated) {
        Navigator.pushNamed(context, '/blogs/detail', arguments: {'blogId': blog.id});
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 0.4),
          builder: (ctx) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: LoginSignupDialog(parentContext: context, onCancel: () {}),
          ),
        );
      }
    }

    return PressableScale(
      onTap: handleTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E1464).withValues(alpha: 0.14),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              blog.image.isNotEmpty
                  ? Image.network(
                      blog.image,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1E1464), Color(0xFF2D3B8F)],
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.article_outlined, size: 32, color: Colors.white24),
                        ),
                      ),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E1464), Color(0xFF2D3B8F)],
                        ),
                      ),
                    ),

              // Top vignette so badge stays readable over any image
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.38),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Category badge + arrow (top row)
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: blog.featured
                            ? const Color(0xFFF9B000)
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: blog.featured
                              ? Colors.transparent
                              : Colors.white.withValues(alpha: 0.4),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        blog.featured ? 'FEATURED' : 'NEWS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_outward_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom: thin golden line + navy content strip
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(height: 2, color: const Color(0xFFF9B000)),
                    Container(
                      height: stripHeight,
                      color: const Color(0xFF1E1464).withValues(alpha: 0.93),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            blog.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              letterSpacing: 0.05,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.person_rounded, size: 9, color: Colors.white54),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  blog.author.isNotEmpty ? blog.author : 'Bansal Immigration',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFBBBBBB),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF9B000),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                blog.date,
                                style: const TextStyle(
                                  color: Color(0xFFAAAAAA),
                                  fontSize: 9.5,
                                ),
                              ),
                            ],
                          ),
                        ],
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

  Widget _buildSkeletonCard(double cardWidth, int index) {
    return Container(
      width: cardWidth,
      margin: EdgeInsets.only(right: index == 2 ? 0 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Expanded(child: Container(color: Colors.grey.shade200)),
            Container(height: 2, color: Colors.grey.shade300),
            Container(
              height: 64,
              color: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    height: 9,
                    width: cardWidth * 0.55,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
