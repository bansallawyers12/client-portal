import 'package:client/screens/dashboard/notification/notification_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/theme_config.dart';
import '../../../models/notification/notification.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_loader.dart';
import '../../../utils/cache_helper.dart';
import '../../../utils/responsive_utils.dart';
import '../../workflow/message/workflow_messages_screen.dart';
import '../../workflow/workflow_stages_screen.dart';
import '../billing_list/billing_list_screen.dart';
import '../personal_info/personal_information_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;
  final int limit = 20;
  bool isNavigating = false;
  List<NotificationModel> notifications = [];
  final ScrollController _scrollController = ScrollController();

  String get _cacheKey =>
      'notifications_${AuthService.selectedMatterId ?? 0}_v1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !isLoading &&
          hasMore) {
        fetchNotifications();
      }
    });
  }

  // Shows the cached first page instantly, then refreshes from the network
  // in the background (stale-while-revalidate) so no loader is shown on revisit.
  Future<void> _init() async {
    final cached = await CacheHelper.loadEnvelope(
      _cacheKey,
      maxAge: const Duration(days: 3),
    );
    if (cached is List && cached.isNotEmpty && mounted) {
      setState(() {
        notifications = cached
            .map<NotificationModel>(
              (e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
        currentPage = 2;
        isLoading = false;
      });
    }
    await _loadFirstPage(silent: notifications.isNotEmpty);
  }

  // Fetches page 1, replaces the list and updates the cache.
  Future<void> _loadFirstPage({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => isLoading = true);

    try {
      final data = await ApiService.getNotifications(
        clientMatterId: AuthService.selectedMatterId ?? 0,
        page: 1,
        limit: limit,
      );

      final list = (data['data']['notifications'] as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      if (!mounted) return;
      setState(() {
        notifications = list;
        currentPage = 2;
        hasMore = currentPage <= data['data']['pagination']['last_page'];
        isLoading = false;
      });

      await CacheHelper.saveEnvelope(
        key: _cacheKey,
        data: list.map((n) => n.toJson()).toList(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      if (notifications.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> fetchNotifications() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final data = await ApiService.getNotifications(
        clientMatterId: AuthService.selectedMatterId ?? 0,
        page: currentPage,
        limit: limit,
      );

      final newNotifications =
          (data['data']['notifications'] as List)
              .map((json) => NotificationModel.fromJson(json))
              .toList();

      if (!mounted) return;
      setState(() {
        currentPage++;
        notifications.addAll(newNotifications);
        hasMore = currentPage <= data['data']['pagination']['last_page'];
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    await _loadFirstPage(silent: true);
  }

  // Groups notifications by day into sections, each rendered as one card.
  List<({String label, List<NotificationModel> items})> _buildSections() {
    final sections = <({String label, List<NotificationModel> items})>[];
    for (final n in notifications) {
      final label = _dateGroupLabel(n.createdAt);
      if (sections.isEmpty || sections.last.label != label) {
        sections.add((label: label, items: [n]));
      } else {
        sections.last.items.add(n);
      }
    }
    return sections;
  }

  String _dateGroupLabel(DateTime dt) {
    final now = DateTime.now();
    final day = DateTime(dt.year, dt.month, dt.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return DateFormat('EEEE').format(dt);
    return DateFormat('MMMM d, yyyy').format(dt);
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM dd, yyyy').format(dt);
  }

  Widget _dateHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // Maps a notification type to a meaningful icon + accent color.
  (IconData, Color) _visualForType(String type) {
    switch (type.trim()) {
      case 'message':
        return (Icons.chat_bubble_rounded, const Color(0xFF3B82F6));
      case 'stage_change':
        return (Icons.swap_horiz_rounded, const Color(0xFF8B5CF6));
      case 'checklist':
      case 'checklist_added':
        return (Icons.checklist_rounded, const Color(0xFFF59E0B));
      case 'document_approved':
        return (Icons.verified_rounded, const Color(0xFF10B981));
      case 'document_rejected':
      case 'document_deleted':
        return (Icons.report_gmailerrorred_rounded, const Color(0xFFEF4444));
      case 'document_downloaded':
        return (Icons.download_rounded, const Color(0xFF0EA5E9));
      case 'invoice_sent_to_client_app':
        return (Icons.receipt_long_rounded, const Color(0xFF14B8A6));
      case 'detail_approved':
      case 'detail_rejected':
        return (Icons.person_rounded, const Color(0xFF6366F1));
      case 'matter_discontinued':
        return (Icons.pause_circle_filled_rounded, const Color(0xFFEF4444));
      case 'matter_reopened':
        return (Icons.play_circle_fill_rounded, const Color(0xFF10B981));
      case 'action_completed':
        return (Icons.task_alt_rounded, const Color(0xFF10B981));
      case 'lead_converted_to_client':
        return (Icons.how_to_reg_rounded, const Color(0xFF10B981));
      default:
        return (Icons.notifications_rounded, ThemeConfig.primaryColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppResponsive.isDesktop(context);

    final int unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: ThemeConfig.goldenYellow,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Notifications",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              unreadCount > 0
                  ? '$unreadCount unread'
                  : "You're all caught up",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w400,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppResponsive.maxContentWidth,
            ),
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: isLoading && notifications.isEmpty
                  ? const Center(child: AppLoader())
                  : notifications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: ThemeConfig.primaryColor.withValues(
                                    alpha: 0.08,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.notifications_none_rounded,
                                  size: 40,
                                  color: ThemeConfig.primaryColor.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No notifications yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: ThemeConfig.textSecondaryLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "You're all caught up",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: ThemeConfig.textSecondaryLight
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Builder(
                          builder: (context) {
                            final sections = _buildSections();
                            return ListView.builder(
                              controller: _scrollController,
                              itemCount: sections.length + (hasMore ? 1 : 0),
                              padding: AppResponsive.horizontalPadding(
                                context,
                              ).copyWith(top: 6, bottom: 24),
                              itemBuilder: (context, index) {
                                if (index == sections.length) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Center(child: AppLoader()),
                                  );
                                }
                                final section = sections[index];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _dateHeader(section.label),
                                    _sectionCard(section.items, isDesktop),
                                  ],
                                );
                              },
                            );
                          },
                        ),
            ),
          ),
        ),
      ),
    );
  }

  // One rounded card per day holding all that day's notifications, separated
  // by hairline dividers — a cleaner alternative to a wall of separate cards.
  Widget _sectionCard(List<NotificationModel> items, bool isDesktop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEF1F5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.only(left: 68),
                child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
              ),
            _itemRow(items[i], isDesktop),
          ],
        ],
      ),
    );
  }

  Widget _itemRow(NotificationModel item, bool isDesktop) {
    final bool isUnread = !item.isRead;
    final (IconData icon, Color accent) = _visualForType(item.notificationType);
    const double iconBox = 42;

    return Material(
      color: isUnread ? const Color(0xFFFFFBF0) : Colors.white,
      child: InkWell(
        onTap: () async {
          await _handleNotificationTap(context, item);
          if (mounted) _refresh();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: isDesktop ? 15 : 14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: iconBox,
                height: iconBox,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.message,
                      style: TextStyle(
                        fontWeight:
                            isUnread ? FontWeight.w600 : FontWeight.w500,
                        fontSize: isDesktop ? 15 : 14,
                        height: 1.4,
                        color: isUnread
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.senderName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '•',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFCBD5E1),
                            ),
                          ),
                        ),
                        Text(
                          _relativeTime(item.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isUnread)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 5),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: ThemeConfig.goldenYellow,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    NotificationModel item,
  ) async {
    if (isNavigating) return;
    isNavigating = true;

    try {
      if (!item.isRead) {
        await ApiService.markNotificationAsRead(notificationId: item.id);
        item.isRead = true;
      }

      final Map<String, dynamic> matters = await ApiService.getMatters();
      final int matterId = item.clientMatterId;

      String? matterName;
      if (matters["data"]["matters"] != null) {
        for (var m in matters["data"]["matters"]) {
          if (m["matter_id"] == matterId) {
            matterName = m["matter_name"] ?? "";
            break;
          }
        }
      }
      matterName ??= "Unknown";

      await AuthService.selectMatter(
        matterId: matterId,
        matterName: matterName,
      );

      Widget? screen;

      final type = item.notificationType.trim();
      final url = item.url.trim();

      switch (type) {
        case "message":
          screen = WorkflowMessagesScreen(matterID: matterId);
          break;

        case "stage_change":
        case "matter_discontinued":
        case "matter_reopened":
        case "checklist":
        case "checklist_added":
        case "document_approved":
        case "document_rejected":
        case "document_deleted":
        case "document_downloaded":
          screen = WorkflowStagesScreen(matterID: matterId);
          break;

        case "detail_approved":
        case "detail_rejected":
          screen = PersonalInformationScreen();
          break;

        case "invoice_sent_to_client_app":
          screen = BillingListScreen(matterID: matterId);
          break;

        case "action_completed":
          if (url == "/activities") {
            screen = WorkflowStagesScreen(matterID: matterId);
          } else {
            screen = NotificationDetailScreen(notificationId: item.id);
          }
          break;

        case "lead_converted_to_client":
          screen = NotificationDetailScreen(notificationId: item.id);
          break;

        default:
          screen = NotificationDetailScreen(notificationId: item.id);
          break;
      }

      if (!mounted) return;

      await Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
    } finally {
      isNavigating = false;
    }
  }
}
