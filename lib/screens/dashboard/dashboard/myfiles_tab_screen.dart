import 'dart:ui';

import 'package:client/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/theme_config.dart';
import '../../../main.dart';
import '../../../models/action_required.dart';
import '../../../models/notification/notification.dart';
import '../../../models/workflow_stage.dart';
import '../../../services/api_service.dart';
import '../../../utils/app_loader.dart';
import '../../../utils/cache_helper.dart';
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
    with RouteAware, WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  bool _isBlocked = false;
  bool _isLoading = true;
  bool _isNavigating = false;

  List<NotificationModel> notifications = [];
  bool isFetchingNotifications = false;

  // Action Required state
  int _actionRequiredCount = 0;
  Map<String, dynamic>? _latestActionRequired;
  bool _isFetchingActionRequired = false;
  List<ActionRequiredModel> _actionItems = [];

  // Workflow / case stages
  WorkflowStagesResponse? _workflow;
  bool _isFetchingWorkflow = false;

  static const String _notificationsCacheKey = 'myfiles_notifications_v1';
  static const String _actionRequiredCacheKey = 'myfiles_action_required_v1';
  static const String _workflowCacheKey = 'myfiles_workflow_v1';
  static const String _actionListCacheKey = 'myfiles_action_list_v1';

  String get _cacheScope =>
      AuthService.selectedMatterId?.toString() ?? 'guest';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (AuthService.isAuthenticated && AuthService.isMatterSelected) {
      if (mounted) setState(() => _isLoading = false);
    }

    await _loadFromCache();
    _checkUserStatus(silent: true);
    _fetchNotifications();
    _fetchActionRequired();
    _fetchActionList();
    _fetchWorkflow();
  }

  Future<void> _loadFromCache() async {
    final scope = _cacheScope;

    final cachedNotifications = await CacheHelper.loadEnvelope(
      '${_notificationsCacheKey}_$scope',
    );
    if (cachedNotifications is List && cachedNotifications.isNotEmpty) {
      notifications = cachedNotifications
          .map(
            (e) => NotificationModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    }

    final cachedActionRequired = await CacheHelper.loadEnvelope(
      '${_actionRequiredCacheKey}_$scope',
    );
    if (cachedActionRequired is Map) {
      final data = Map<String, dynamic>.from(cachedActionRequired);
      _actionRequiredCount = data['unread_count'] as int? ?? 0;
      final latest = data['latest_unread'];
      _latestActionRequired =
          latest is Map ? Map<String, dynamic>.from(latest) : null;
    }

    final cachedWorkflow = await CacheHelper.loadEnvelope(
      '${_workflowCacheKey}_$scope',
      maxAge: const Duration(hours: 6),
    );
    if (cachedWorkflow is Map) {
      try {
        _workflow = WorkflowStagesResponse.fromJson(
          Map<String, dynamic>.from(cachedWorkflow),
        );
      } catch (_) {}
    }

    final cachedActions = await CacheHelper.loadEnvelope(
      '${_actionListCacheKey}_$scope',
      maxAge: const Duration(hours: 6),
    );
    if (cachedActions is List) {
      _actionItems = cachedActions
          .map(
            (e) => ActionRequiredModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    }

    if (mounted &&
        (notifications.isNotEmpty ||
            _actionRequiredCount > 0 ||
            _workflow != null ||
            _actionItems.isNotEmpty)) {
      setState(() => _isLoading = false);
    }
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
    _checkUserStatus(silent: true);
    _fetchNotifications();
    _fetchActionRequired();
    _fetchActionList();
    _fetchWorkflow();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchNotifications(forceRefresh: true);
      _fetchActionRequired(forceRefresh: true);
      _fetchActionList(forceRefresh: true);
      _fetchWorkflow(forceRefresh: true);
    }
  }

  Future<void> _fetchActionRequired({bool forceRefresh = false}) async {
    final bool isLoggedIn = AuthService.isAuthenticated;
    if (!isLoggedIn || !mounted || _isFetchingActionRequired) return;

    final scope = _cacheScope;
    final cacheKey = '${_actionRequiredCacheKey}_$scope';
    final hasCachedData = _actionRequiredCount > 0 || _latestActionRequired != null;

    if (!forceRefresh && !hasCachedData) {
      final cached = await CacheHelper.loadEnvelope(cacheKey);
      if (cached is Map) {
        final data = Map<String, dynamic>.from(cached);
        if (mounted) {
          setState(() {
            _actionRequiredCount = data['unread_count'] as int? ?? 0;
            final latest = data['latest_unread'];
            _latestActionRequired =
                latest is Map ? Map<String, dynamic>.from(latest) : null;
          });
        }
      }
    }

    final showLoader = _actionRequiredCount == 0 && _latestActionRequired == null;
    if (showLoader && mounted) {
      setState(() => _isFetchingActionRequired = true);
    }

    try {
      final data = await ApiService.getActionRequired();

      if (!mounted) return;

      if (data['success'] == true) {
        final payload = {
          'unread_count': data['data']['unread_count'] ?? 0,
          'latest_unread': data['data']['latest_unread'],
        };
        await CacheHelper.saveEnvelope(key: cacheKey, data: payload);
        setState(() {
          _actionRequiredCount = payload['unread_count'] as int;
          final latest = payload['latest_unread'];
          _latestActionRequired =
              latest is Map ? Map<String, dynamic>.from(latest) : null;
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

  Future<void> _fetchActionList({bool forceRefresh = false}) async {
    if (!AuthService.isAuthenticated || !mounted) return;

    final cacheKey = '${_actionListCacheKey}_$_cacheScope';
    try {
      final data = await ApiService.getActionRequiredList(page: 1, limit: 5);
      if (!mounted) return;

      final inner = data['data'] ?? {};
      List list = [];
      if (inner['action_required'] is List) {
        list = inner['action_required'];
      } else if (inner['data'] is List) {
        list = inner['data'];
      }

      final items = list
          .map(
            (e) => ActionRequiredModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();

      await CacheHelper.saveEnvelope(
        key: cacheKey,
        data: items
            .map(
              (e) => {
                'id': e.id,
                'type': e.type,
                'client_id': e.clientId,
                'client_matter_id': e.clientMatterId,
                'checklist_id': e.checklistId,
                'sender_id': e.senderId,
                'receiver_id': e.receiverId,
                'module_id': e.moduleId,
                'url': e.url,
                'notification_type': e.notificationType,
                'message': e.message,
                'sender_status': e.senderStatus,
                'receiver_status': e.receiverStatus,
                'seen': e.seen,
                'created_at': e.createdAt.toIso8601String(),
                'updated_at': e.updatedAt.toIso8601String(),
                'sender_name': e.senderName,
              },
            )
            .toList(),
      );

      setState(() => _actionItems = items);
    } catch (e) {
      debugPrint('Action list fetch error: $e');
    }
  }

  Future<void> _fetchWorkflow({bool forceRefresh = false}) async {
    if (!AuthService.isAuthenticated ||
        !AuthService.isMatterSelected ||
        !mounted ||
        _isFetchingWorkflow) {
      return;
    }

    _isFetchingWorkflow = true;
    final cacheKey = '${_workflowCacheKey}_$_cacheScope';

    try {
      final response = await ApiService.getWorkflowStages(
        clientMatterId: AuthService.selectedMatterId,
        type: 'all',
      );
      if (!mounted) return;

      final data = response['data'] ?? response;
      if (data is Map) {
        final workflow = WorkflowStagesResponse.fromJson(
          Map<String, dynamic>.from(data),
        );
        await CacheHelper.saveEnvelope(key: cacheKey, data: data);
        setState(() => _workflow = workflow);
      }
    } catch (e) {
      debugPrint('Workflow fetch error: $e');
    } finally {
      _isFetchingWorkflow = false;
    }
  }

  Future<void> _fetchNotifications({bool forceRefresh = false}) async {
    final bool isLoggedIn = AuthService.isAuthenticated;
    if (!isLoggedIn || !mounted || isFetchingNotifications) return;

    final scope = _cacheScope;
    final cacheKey = '${_notificationsCacheKey}_$scope';

    if (!forceRefresh && notifications.isEmpty) {
      final cached = await CacheHelper.loadEnvelope(cacheKey);
      if (cached is List && cached.isNotEmpty) {
        final cachedNotifications = cached
            .map(
              (e) => NotificationModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
        if (mounted) {
          setState(() => notifications = cachedNotifications);
        }
      }
    }

    final showLoader = notifications.isEmpty;
    if (showLoader && mounted) {
      setState(() => isFetchingNotifications = true);
    }

    try {
      final data = await ApiService.getRecentUnreadNotifications();

      final newNotifications =
          (data['data']['notifications'] as List)
              .map((json) => NotificationModel.fromJson(json))
              .toList();

      await CacheHelper.saveEnvelope(
        key: cacheKey,
        data: newNotifications.map((e) => e.toJson()).toList(),
      );

      if (!mounted) return;

      setState(() {
        notifications = newNotifications;
        isFetchingNotifications = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isFetchingNotifications = false);
      if (notifications.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load notifications: $e")),
        );
      }
    }
  }

  Future<void> _checkUserStatus({bool silent = false}) async {
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

      if (!silent && mounted) {
        setState(() => _isLoading = true);
      }
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

  Widget _buildGuestPrompt() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeConfig.navyBlue.withValues(alpha: 0.04),
            ThemeConfig.goldenYellow.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: ThemeConfig.goldenYellow.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              color: ThemeConfig.goldenYellow,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Sign in to access your files',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: ThemeConfig.navyBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View workflow progress, upload documents, pay invoices, and message your consultant.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: ThemeConfig.navyBlue.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConfig.goldenYellow,
                foregroundColor: ThemeConfig.navyBlue,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Sign in',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/register');
            },
            child: const Text(
              'Create free account',
              style: TextStyle(
                color: ThemeConfig.goldenYellow,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: AppLoader());
    }

    final currentStage =
        _workflow?.activeStage?.stageName ??
        _workflow?.activeStage?.name;
    final progress = _workflow?.progressPercentage ?? 0;
    final matterNo = _workflow?.activeStage?.clientMatterNo;

    final quickActionsCard = MyFilesQuickActionsCard(
      currentStageName: currentStage,
      progressPercent: progress,
      matterNumber: matterNo,
      onViewWorkflow: () {
        Navigator.pushNamed(
          context,
          '/workflow-stages',
          arguments: {"matter_id": AuthService.selectedMatterId},
        );
      },
      onMyFiles: () {
        Navigator.pushNamed(context, '/my-files');
      },
      onBilling: () {
        Navigator.pushNamed(
          context,
          '/billing-list',
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

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (AuthService.isAuthenticated) _buildCaseUpdateCard(),
        if (_actionRequiredCount > 0) _buildActionRequiredBanner(),
        quickActionsCard,
        const SizedBox(height: 10),
        if (AuthService.isAuthenticated) ...[
          _buildActionsAssignedSection(),
          _buildCaseStagesSection(),
        ],
        if (!AuthService.isAuthenticated) _buildGuestPrompt(),
        const SizedBox(height: 24),
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: AbsorbPointer(
          absorbing: _isBlocked,
          child: RefreshIndicator(
            color: ThemeConfig.goldenYellow,
            onRefresh: () async {
              await Future.wait([
                _fetchNotifications(forceRefresh: true),
                _fetchActionRequired(forceRefresh: true),
                _fetchActionList(forceRefresh: true),
                _fetchWorkflow(forceRefresh: true),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppResponsive.maxContentWidth,
                  ),
                  child: Padding(
                    padding: AppResponsive.pagePadding(context).copyWith(
                      top: 12,
                    ),
                    child: content,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaseUpdateCard() {
    if (isFetchingNotifications && notifications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 14),
        child: Center(child: AppLoader()),
      );
    }
    if (notifications.isEmpty) return const SizedBox.shrink();

    final item = notifications.first;
    final initial =
        item.senderName.isNotEmpty ? item.senderName[0].toUpperCase() : 'B';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleNotificationTap(context, item),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEEF1F5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: ThemeConfig.goldenYellow),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: ThemeConfig.navyBlue,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Update on your case',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: ThemeConfig.navyBlue,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.message,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.35,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${item.senderName} • ${_relativeTime(item.createdAt)}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 18,
                            color: Colors.grey.shade400,
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

  Widget _sectionHeader(String title, {VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: ThemeConfig.navyBlue,
              ),
            ),
          ),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                foregroundColor: ThemeConfig.goldenYellow,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'View all',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionsAssignedSection() {
    if (_actionItems.isEmpty && _actionRequiredCount == 0) {
      return const SizedBox.shrink();
    }

    final items = _actionItems.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          'Actions assigned by Bansal Immigration',
          onViewAll: () => Navigator.pushNamed(context, '/action-required'),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEF1F5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    _actionRequiredCount > 0
                        ? '$_actionRequiredCount action(s) pending — tap View all'
                        : 'No pending actions',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                )
              else
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _actionAssignedRow(items[i]),
                ],
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/workflow-stages',
                    arguments: {'matter_id': AuthService.selectedMatterId},
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.upload_rounded,
                        size: 18,
                        color: ThemeConfig.navyBlue,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Upload Document',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: ThemeConfig.navyBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _actionAssignedRow(ActionRequiredModel item) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/action-required'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ThemeConfig.goldenYellow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.note_add_rounded,
                    color: ThemeConfig.goldenYellow,
                    size: 20,
                  ),
                ),
                if (!item.isRead)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: ThemeConfig.navyBlue,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Requested on ${DateFormat('d MMM yyyy').format(item.createdAt)}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ThemeConfig.goldenYellow.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Pending',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB45309),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseStagesSection() {
    if (_workflow == null) return const SizedBox.shrink();

    final stages = _workflow!.workflowStages;
    if (stages.isEmpty) return const SizedBox.shrink();

    final currentIndex = _workflow!.currentStageIndex;
    final start =
        currentIndex <= 0 ? 0 : (currentIndex - 1).clamp(0, stages.length - 1);
    final end = (currentIndex < 0 ? 0 : currentIndex)
        .clamp(0, stages.length - 1);
    final visible = <({WorkflowStage stage, int index})>[];
    for (int i = start; i <= end && i < stages.length; i++) {
      visible.add((stage: stages[i], index: i));
    }
    if (visible.isEmpty) {
      visible.add((stage: stages.first, index: 0));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          'Case Stages',
          onViewAll: () {
            Navigator.pushNamed(
              context,
              '/workflow-stages',
              arguments: {'matter_id': AuthService.selectedMatterId},
            );
          },
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEF1F5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < visible.length; i++)
                _stageTimelineRow(
                  stage: visible[i].stage,
                  number: visible[i].index + 1,
                  isLast: i == visible.length - 1,
                  currentIndex: currentIndex,
                  stageIndex: visible[i].index,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _stageTimelineRow({
    required WorkflowStage stage,
    required int number,
    required bool isLast,
    required int currentIndex,
    required int stageIndex,
  }) {
    final isCompleted = currentIndex >= 0 && stageIndex < currentIndex;
    final isCurrent = stage.isCurrentStage ||
        (currentIndex >= 0 && stageIndex == currentIndex);
    final statusLabel = isCompleted
        ? 'Completed'
        : (isCurrent ? 'In Progress' : 'Upcoming');
    final statusColor = isCompleted
        ? const Color(0xFF16A34A)
        : (isCurrent ? ThemeConfig.goldenYellow : const Color(0xFF94A3B8));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: (isCompleted || isCurrent)
                        ? ThemeConfig.navyBlue
                        : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: (isCompleted || isCurrent)
                          ? Colors.white
                          : const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: ThemeConfig.navyBlue.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 8 : 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage.stageName.isNotEmpty
                              ? stage.stageName
                              : stage.name,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: ThemeConfig.navyBlue,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isCompleted)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF16A34A),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ],
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

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

}
