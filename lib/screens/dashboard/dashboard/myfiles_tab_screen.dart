import 'dart:ui';

import 'package:client/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/theme_config.dart';
import '../../../main.dart';
import '../../../models/notification/notification.dart';
import '../../../services/api_service.dart';
import '../../../utils/app_loader.dart';
import '../../../utils/responsive_utils.dart';
import '../../../widgets/dialog/login_required_dialog.dart';
import '../../workflow/message/workflow_messages_screen.dart';
import '../../workflow/workflow_stages_screen.dart';
import '../billing_list/billing_list_screen.dart';
import '../my_files/my_files_quick_action_card.dart';
import '../notification/notification_detail_screen.dart';
import '../personal_info/personal_information_screen.dart';

class MyFilesTabScreen extends StatefulWidget {
  const MyFilesTabScreen({super.key});

  @override
  State<MyFilesTabScreen> createState() => _MyFilesTabScreenState();
}

class _MyFilesTabScreenState extends State<MyFilesTabScreen>
    with RouteAware, WidgetsBindingObserver {
  bool _isBlocked = false;
  bool _isLoading = true;
  bool _isNavigating = false;

  List<NotificationModel> notifications = [];
  bool isFetchingNotifications = false;

  // Action Required state
  int _actionRequiredCount = 0;
  Map<String, dynamic>? _latestActionRequired;
  bool _isFetchingActionRequired = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkUserStatus();
    _fetchNotifications();
    _fetchActionRequired();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _checkUserStatus();
    _fetchNotifications();
    _fetchActionRequired();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchNotifications();
      _fetchActionRequired();
    }
  }

  Future<void> _fetchActionRequired() async {
    final bool isLoggedIn = AuthService.isAuthenticated;
    if (!isLoggedIn || !mounted || _isFetchingActionRequired) return;

    setState(() => _isFetchingActionRequired = true);

    try {
      final data = await ApiService.getActionRequired();

      if (!mounted) return;

      if (data['success'] == true) {
        setState(() {
          _actionRequiredCount = data['data']['unread_count'] ?? 0;
          _latestActionRequired = data['data']['latest_unread'];
          _isFetchingActionRequired = false;
        });
      } else {
        setState(() => _isFetchingActionRequired = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFetchingActionRequired = false);
    }
  }

  Future<void> _fetchNotifications() async {
    final bool isLoggedIn = AuthService.isAuthenticated;
    if (!isLoggedIn || !mounted || isFetchingNotifications) return;

    setState(() => isFetchingNotifications = true);

    try {
      final data = await ApiService.getRecentUnreadNotifications();

      final newNotifications =
          (data['data']['notifications'] as List)
              .map((json) => NotificationModel.fromJson(json))
              .toList();

      if (!mounted) return;

      setState(() {
        notifications = newNotifications;
        isFetchingNotifications = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isFetchingNotifications = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load notifications: $e")),
      );
    }
  }

  Future<void> _checkUserStatus() async {
    try {
      final bool isLoggedIn = AuthService.isAuthenticated;
      if (!isLoggedIn) {
        setState(() => _isLoading = false);

        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 0.4),
          builder: (context) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: LoginRequiredDialog(
                parentContext: context,
                onCancel: () {
                  DefaultTabController.of(this.context).animateTo(0);
                },
              ),
            );
          },
        );

        return;
      }

      final bool matterSelected = AuthService.isMatterSelected;
      if (isLoggedIn && matterSelected) {
        setState(() => _isLoading = false);
        return;
      }

      setState(() => _isLoading = true);
      final result = await ApiService.checkUserAuthentication();

      if (result['success'] == true) {
        int status = result['data']['cp_status'];

        if (status == 1) {
          _showMatterSelect();
        } else if (status == 2) {
          setState(() {
            _isBlocked = true;
          });

          Future.delayed(Duration.zero, () {
            _showBlockedDialog();
          });
        }
      }
    } catch (e) {
      debugPrint("Error checking user status: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showBlockedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text("Access Restricted"),
            content: const Text(
              "Your account approval is pending. Please contact support.",
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  DefaultTabController.of(this.context).animateTo(0);
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMatterSelect() {
    if (!AuthService.isMatterSelected) {
      final parentContext = context;

      showDialog(
        context: parentContext,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.4),
        builder: (context) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text("Select Matter"),
              content: const Text("Please select a matter to continue."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    DefaultTabController.of(parentContext).animateTo(0);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(parentContext, '/matters');
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildActionRequiredBanner() {
    if (_actionRequiredCount == 0 && !_isFetchingActionRequired) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 3,
        shadowColor: const Color(0xFFEA580C).withValues(alpha: 0.2),
        color: Colors.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap:
              _isFetchingActionRequired
                  ? null
                  : () {
                    if (_latestActionRequired != null) {
                      Navigator.pushNamed(context, '/action-required');
                    }
                  },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF3E0), Color(0xFFFFCCBC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: const Color(0xFFFB923C).withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icon with urgent dot
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.assignment_late_rounded,
                        color: Color(0xFFEA580C),
                        size: 22,
                      ),
                    ),
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child:
                      _isFetchingActionRequired
                          ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 13,
                                width: 120,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFEA580C,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 11,
                                width: 180,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFEA580C,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          )
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Action Required',
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF9A3412),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$_actionRequiredCount',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_latestActionRequired != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  _latestActionRequired!['message']
                                          as String? ??
                                      '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ],
                          ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFFEA580C),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel item) {
    final bool isUnread = !item.isRead;
    final isDesktop = AppResponsive.isDesktop(context);
    final double radius = isDesktop ? 16 : 12;

    // Platform-specific backgrounds
    final Color cardBg =
        isDesktop
            ? (isUnread ? const Color(0xFFEDF5F3) : ThemeConfig.backgroundLight)
            : (isUnread ? const Color(0xFFF0F7F5) : Colors.white);

    final Color avatarBg =
        isUnread
            ? ThemeConfig.primaryColor
            : (isDesktop ? ThemeConfig.borderLight : const Color(0xFFF1F5F9));
    final Color avatarTextColor =
        isUnread ? Colors.white : ThemeConfig.primaryColor;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 6 : 4),
      child: Material(
        borderRadius: BorderRadius.circular(radius),
        elevation: isDesktop ? 2 : 1,
        shadowColor: Colors.black.withValues(alpha: isDesktop ? 0.08 : 0.05),
        color: cardBg,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: () => _handleNotificationTap(context, item),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent strip — teal for unread, transparent for read
                  Container(
                    width: 4,
                    color:
                        isUnread
                            ? ThemeConfig.primaryColor
                            : Colors.transparent,
                  ),
                  Expanded(
                    child: Padding(
                      padding:
                          isDesktop
                              ? const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 16,
                              )
                              : const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: isDesktop ? 26 : 21,
                            backgroundColor: avatarBg,
                            child: Text(
                              item.senderName[0].toUpperCase(),
                              style: TextStyle(
                                color: avatarTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: isDesktop ? 16 : 14,
                              ),
                            ),
                          ),
                          SizedBox(width: isDesktop ? 16 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.message,
                                  style: TextStyle(
                                    fontWeight:
                                        isUnread
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                    fontSize: isDesktop ? 15.5 : 14.5,
                                    color:
                                        isUnread
                                            ? ThemeConfig.textPrimaryLight
                                            : ThemeConfig.textSecondaryLight,
                                  ),
                                ),
                                SizedBox(height: isDesktop ? 5 : 4),
                                Text(
                                  '${item.senderName} • ${_relativeTime(item.createdAt)}',
                                  style: TextStyle(
                                    fontSize: isDesktop ? 13 : 12,
                                    color: ThemeConfig.textSecondaryLight
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: isDesktop ? 12 : 8),
                          Icon(
                            isUnread
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_none_rounded,
                            color:
                                isUnread
                                    ? ThemeConfig.primaryColor
                                    : Colors.grey.shade400,
                            size: isDesktop ? 22 : 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    if (!isFetchingNotifications && notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDesktop = AppResponsive.isDesktop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDesktop)
          Padding(
            padding: AppResponsive.horizontalPadding(context).copyWith(top: 24),
            child: Container(
              width: 28,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFF9B000),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        const SizedBox(height: 12),
        if (isFetchingNotifications)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: AppLoader(),
            ),
          )
        else
          Padding(
            padding: AppResponsive.horizontalPadding(context),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notifications.length,
              itemBuilder: (context, index) =>
                  _buildNotificationItem(notifications[index]),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: AppLoader());
    }

    final isDesktop = AppResponsive.isDesktop(context);

    final quickActionsCard = MyFilesQuickActionsCard(
      onViewWorkflow: () {
        Navigator.pushNamed(
          context,
          '/workflow-stages',
          arguments: {"matter_id": AuthService.selectedMatterId},
        );
      },
      onBilling: () {
        Navigator.pushNamed(
          context,
          '/billing-list',
          arguments: {"matter_id": AuthService.selectedMatterId},
        );
      },
      onDocumentStatus: () {
        Navigator.pushNamed(
          context,
          '/documents',
          arguments: {"matter_id": AuthService.selectedMatterId},
        );
      },
      onUpcomingDeadlines: () {
        Navigator.pushNamed(
          context,
          '/tasks',
          arguments: {"matter_id": AuthService.selectedMatterId},
        );
      },
      onMessage: () {
        Navigator.pushNamed(
          context,
          '/workflow-message',
          arguments: {"matter_id": AuthService.selectedMatterId},
        );
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFF223344),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF223344), Color(0xFF101722)],
          ),
        ),
        child: SafeArea(
          child: AbsorbPointer(
            absorbing: _isBlocked,
          child:
              isDesktop
                  // Web: same structure as DashboardTabScreen
                  ? SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppResponsive.maxContentWidth,
                        ),
                        child: Container(
                          color: const Color(0xFFF8FAFC),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (AuthService.isAuthenticated)
                                _buildNotificationsSection(),
                              const SizedBox(height: 24),
                              Padding(
                                padding: AppResponsive.pagePadding(context)
                                    .copyWith(top: 12),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildActionRequiredBanner(),
                                    quickActionsCard,
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  // Mobile
                  : SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppResponsive.maxContentWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (AuthService.isAuthenticated)
                              _buildNotificationsSection(),
                            Padding(
                              padding: AppResponsive.pagePadding(context),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildActionRequiredBanner(),
                                  quickActionsCard,
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
    );
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    NotificationModel item,
  ) async {
    if (_isNavigating) return;
    _isNavigating = true;

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
      _isNavigating = false;
    }
  }

  ({IconData icon, Color color}) _notificationStyle(String type) {
    return switch (type) {
      'message' => (
        icon: Icons.chat_bubble_rounded,
        color: const Color(0xFF2E7D32),
      ),
      'invoice_sent_to_client_app' => (
        icon: Icons.receipt_long_rounded,
        color: const Color(0xFFC62828),
      ),
      'detail_approved' => (
        icon: Icons.verified_rounded,
        color: const Color(0xFF1565C0),
      ),
      'detail_rejected' => (
        icon: Icons.cancel_rounded,
        color: const Color(0xFFB71C1C),
      ),
      'document_approved' => (
        icon: Icons.task_alt_rounded,
        color: const Color(0xFF2E7D32),
      ),
      'document_rejected' => (
        icon: Icons.highlight_off_rounded,
        color: const Color(0xFFB71C1C),
      ),
      'document_deleted' => (
        icon: Icons.delete_forever_rounded,
        color: const Color(0xFF6D4C41),
      ),
      'document_downloaded' => (
        icon: Icons.download_done_rounded,
        color: const Color(0xFF00695C),
      ),
      'stage_change' => (
        icon: Icons.account_tree_rounded,
        color: const Color(0xFF6A1B9A),
      ),
      'checklist' || 'checklist_added' => (
        icon: Icons.checklist_rounded,
        color: const Color(0xFF00838F),
      ),
      'matter_discontinued' => (
        icon: Icons.pause_circle_rounded,
        color: const Color(0xFFE65100),
      ),
      'matter_reopened' => (
        icon: Icons.play_circle_rounded,
        color: const Color(0xFF1B5E20),
      ),
      'lead_converted_to_client' => (
        icon: Icons.person_add_alt_1_rounded,
        color: const Color(0xFF1A237E),
      ),
      'action_completed' => (
        icon: Icons.check_circle_rounded,
        color: const Color(0xFF2E7D32),
      ),
      _ => (icon: Icons.notifications_rounded, color: const Color(0xFF5E8B7E)),
    };
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }
}
