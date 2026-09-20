import 'dart:io';
import 'dart:ui';

import 'package:client/services/auth_service.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../config/client_stage_mapping.dart';
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
  bool _timelineShowAll = false;
  final GlobalKey _documentsSectionKey = GlobalKey();
  final GlobalKey _timelineSectionKey = GlobalKey();
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

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

    final currentStage = _workflow?.currentDisplayName;
    final progress = _workflow?.progressPercentage ?? 0;
    final matterNo = _workflow?.activeStage?.clientMatterNo;
    final statusTag = _workflow?.currentStatusTag;

    final quickActionsCard = MyFilesQuickActionsCard(
      currentStageName:
          (currentStage != null && currentStage.isNotEmpty)
              ? currentStage
              : null,
      progressPercent: progress,
      matterNumber: matterNo,
      statusTagLabel: statusTag?.label,
      statusTagColor: statusTag?.foreground,
      statusTagBackground: statusTag?.background,
      onViewWorkflow: _focusDocumentsUpload,
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
          _buildDocumentsUploadSection(),
          _buildTimelineSection(),
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

  void _openActionRequired() {
    Navigator.pushNamed(context, '/action-required');
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
          onViewAll: _openActionRequired,
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
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _actionRequiredCount > 0 ? _openActionRequired : null,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          Text(
                            _actionRequiredCount > 0
                                ? '$_actionRequiredCount task(s) waiting for you'
                                : 'No pending actions',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          if (_actionRequiredCount > 0) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'View tasks',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: ThemeConfig.navyBlue,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _actionAssignedRow(items[i]),
                ],
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _actionAssignedRow(ActionRequiredModel item) {
    final canUpload = _isUploadAction(item);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _handleActionTap(item),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ThemeConfig.goldenYellow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    canUpload
                        ? Icons.upload_file_rounded
                        : Icons.note_add_rounded,
                    color: ThemeConfig.goldenYellow,
                    size: 20,
                  ),
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
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
          if (canUpload) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _startUploadForAction(item),
                icon: const Icon(Icons.upload_rounded, size: 18),
                label: const Text('Upload document'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ThemeConfig.navyBlue,
                  side: const BorderSide(color: ThemeConfig.navyBlue),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool _isUploadAction(ActionRequiredModel item) {
    if (item.checklistId != null && item.checklistId! > 0) return true;
    final type = '${item.type} ${item.notificationType} ${item.url}'.toLowerCase();
    return type.contains('checklist') ||
        type.contains('document') ||
        type.contains('upload');
  }

  Future<void> _handleActionTap(ActionRequiredModel item) async {
    if (_isUploadAction(item)) {
      await _startUploadForAction(item);
      return;
    }
    _openActionRequired();
  }

  Future<void> _startUploadForAction(ActionRequiredModel item) async {
    final checklistId = item.checklistId;
    WorkflowStage? stage;

    if (_workflow != null) {
      if (checklistId != null && checklistId > 0) {
        for (final s in _workflow!.workflowStages) {
          if (s.allowedChecklist.any((c) => c.id == checklistId)) {
            stage = s;
            break;
          }
        }
      }
      stage ??= _workflow!.currentStage ??
          (_workflow!.workflowStages.isNotEmpty
              ? _workflow!.workflowStages.firstWhere(
                (s) => s.isCurrentStage || s.isActive,
                orElse: () => _workflow!.workflowStages.first,
              )
              : null);
    }

    if (stage == null) {
      if (!mounted) return;
      Navigator.pushNamed(context, '/action-required');
      return;
    }

    final id = checklistId != null && checklistId > 0
        ? checklistId
        : (stage.allowedChecklist.isNotEmpty
            ? stage.allowedChecklist.first.id
            : null);

    if (id == null) {
      _focusDocumentsUpload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Open the document item below and tap + to upload.',
          ),
        ),
      );
      return;
    }

    await _openUploadOptions(stage, id);
  }

  Widget _buildDocumentsUploadSection() {
    if (_workflow == null) return const SizedBox.shrink();

    final stages = _workflow!.workflowStages;
    if (stages.isEmpty) return const SizedBox.shrink();

    final currentIndex = _workflow!.currentStageIndex;
    WorkflowStage? currentStage;
    if (currentIndex >= 0 && currentIndex < stages.length) {
      currentStage = stages[currentIndex];
    } else {
      for (final stage in stages) {
        if (stage.isCurrentStage || stage.isActive) {
          currentStage = stage;
          break;
        }
      }
    }
    // Prototype: show named upload tasks only when the stage has checklist items
    if (currentStage == null || currentStage.allowedChecklist.isEmpty) {
      return const SizedBox.shrink();
    }

    final stage = currentStage;

    return Column(
      key: _documentsSectionKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E7ED)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'YOUR TASKS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: Color(0xFF7A8794),
                      ),
                    ),
                  ),
                  Material(
                    color: ThemeConfig.navyBlue,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _onBulkUploadTap,
                      borderRadius: BorderRadius.circular(24),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.upload_file_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Bulk Upload',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...stage.allowedChecklist.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E7ED)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 20,
                              color: ThemeConfig.navyBlue.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: ThemeConfig.navyBlue,
                                ),
                              ),
                            ),
                            if (item.noOfDocumentUploaded > 0)
                              Text(
                                '${item.noOfDocumentUploaded} uploaded',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF1F8A5B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (item.noOfDocumentUploaded > 0)
                              TextButton.icon(
                                onPressed: () =>
                                    _onViewChecklistDocs(stage, item.id),
                                icon: const Icon(
                                  Icons.remove_red_eye_outlined,
                                  size: 18,
                                ),
                                label: const Text('View'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF1F8A5B),
                                ),
                              ),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _openUploadOptions(stage, item.id),
                                icon: const Icon(Icons.upload_rounded, size: 18),
                                label: const Text('Upload document'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ThemeConfig.navyBlue,
                                  side: const BorderSide(
                                    color: ThemeConfig.navyBlue,
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildTimelineSection() {
    if (_workflow == null) return const SizedBox.shrink();

    final steps = _workflow!.clientTimelineSteps;
    if (steps.isEmpty) return const SizedBox.shrink();

    final currentStep = _workflow!.currentClientStepIndex;
    final List<int> visibleIndexes;
    if (_timelineShowAll) {
      visibleIndexes = List<int>.generate(steps.length, (i) => i);
    } else {
      // Prototype default: completed client steps only
      visibleIndexes = [
        for (int i = 0; i < steps.length; i++)
          if (currentStep >= 0 && i < currentStep) i,
      ];
      if (visibleIndexes.isEmpty && currentStep >= 0) {
        visibleIndexes.add(currentStep);
      }
    }

    return Column(
      key: _timelineSectionKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E7ED)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'TIMELINE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: Color(0xFF7A8794),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _timelineShowAll = !_timelineShowAll);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: ThemeConfig.goldenYellow,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _timelineShowAll ? 'Show less' : 'View all',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (visibleIndexes.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 8, 4, 10),
                  child: Text(
                    'Nothing needed from you right now — we\'ll notify you of any updates.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7A8794),
                      height: 1.35,
                    ),
                  ),
                )
              else
                for (int j = 0; j < visibleIndexes.length; j++)
                  _clientTimelineRow(
                    label: steps[visibleIndexes[j]],
                    isLast: j == visibleIndexes.length - 1,
                    currentIndex: currentStep,
                    stepIndex: visibleIndexes[j],
                  ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _clientTimelineRow({
    required String label,
    required bool isLast,
    required int currentIndex,
    required int stepIndex,
  }) {
    final isCompleted = currentIndex >= 0 && stepIndex < currentIndex;
    final isCurrent = currentIndex >= 0 && stepIndex == currentIndex;
    final accent = isCompleted
        ? const Color(0xFF1F8A5B)
        : (isCurrent ? const Color(0xFF3B6EA5) : const Color(0xFFE2E7ED));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isCompleted ? accent : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: accent, width: 2),
                    boxShadow: isCurrent
                        ? [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.22),
                            blurRadius: 0,
                            spreadRadius: 3,
                          ),
                        ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: isCompleted
                      ? const Icon(
                        Icons.check_rounded,
                        size: 11,
                        color: Colors.white,
                      )
                      : (isCurrent
                          ? Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          )
                          : null),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: isCompleted
                          ? const Color(0xFFBADFCB)
                          : const Color(0xFFE2E7ED),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 6 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                          isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent
                          ? const Color(0xFF12253A)
                          : (isCompleted
                              ? const Color(0xFF7A8794)
                              : const Color(0xFF3A4B5E)),
                      height: 1.3,
                    ),
                  ),
                  if (isCompleted)
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1F8A5B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _focusDocumentsUpload() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _documentsSectionKey.currentContext ??
          _timelineSectionKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          alignment: 0.05,
        );
      }
    });
  }

  Future<void> _onBulkUploadTap() async {
    await Navigator.pushNamed(
      context,
      '/bulk-upload-documents',
      arguments: {
        'matter_id': AuthService.selectedMatterId,
        'stageId': null,
        'allowedChecklistId': null,
      },
    );
    await _fetchWorkflow(forceRefresh: true);
  }

  Future<void> _openUploadOptions(WorkflowStage stage, int checklistId) async {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Add Files',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.folder_open_rounded, color: Color(0xFF5B8DEF)),
                  title: const Text('My Files'),
                  subtitle: const Text('PDF, DOC, DOCX, JPG, PNG'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _pickFromFiles(stage, checklistId);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF8B5CF6)),
                  title: const Text('Gallery'),
                  subtitle: const Text('Pick from your photos'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _pickFromGallery(stage, checklistId);
                  },
                ),
                if (!kIsWeb)
                  ListTile(
                    leading: const Icon(
                      Icons.document_scanner_rounded,
                      color: Color(0xFF10B981),
                    ),
                    title: const Text('Scan Documents'),
                    subtitle: const Text('Auto-crop & capture pages as PDF'),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await _scanDocuments(stage, checklistId);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickFromFiles(WorkflowStage stage, int checklistId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    _selectedFileBytes = file.bytes;
    _selectedFileName = file.name;
    await _uploadDocument(stage, checklistId);
  }

  Future<void> _pickFromGallery(WorkflowStage stage, int checklistId) async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    _selectedFileBytes = await image.readAsBytes();
    _selectedFileName = image.name;
    await _uploadDocument(stage, checklistId);
  }

  Future<void> _scanDocuments(WorkflowStage stage, int checklistId) async {
    try {
      final paths = await CunningDocumentScanner.getPictures(asPdf: true);
      if (paths == null || paths.isEmpty) return;
      _selectedFileBytes = await File(paths.first).readAsBytes();
      _selectedFileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await _uploadDocument(stage, checklistId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scan failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadDocument(WorkflowStage stage, int checklistId) async {
    if (_selectedFileBytes == null || _selectedFileName == null) return;
    final matterId = AuthService.selectedMatterId ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 24, height: 24, child: AppLoader(size: 20)),
              SizedBox(width: 14),
              Text('Uploading document...'),
            ],
          ),
        ),
      ),
    );

    try {
      final response = await ApiService.uploadWorkflowChecklistDocument(
        fileBytes: _selectedFileBytes!,
        fileName: _selectedFileName!,
        allowedChecklistId: checklistId,
        clientMatterId: matterId,
      );
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);

      if (!mounted) return;
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchWorkflow(forceRefresh: true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Upload failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onViewChecklistDocs(WorkflowStage stage, int checklistId) {
    if (stage.allowedChecklistCount <= 0) return;
    Navigator.pushNamed(
      context,
      '/workflow-view-documents-by-checklist',
      arguments: {
        'matter_id': AuthService.selectedMatterId,
        'stageId': stage.id,
        'stageName': stage.displayName,
        'checklistId': checklistId,
      },
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
