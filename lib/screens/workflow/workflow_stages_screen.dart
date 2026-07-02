import 'package:client/config/theme_config.dart';
import 'package:client/widgets/common_app_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/workflow_stage.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_loader.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/workflow/workflow_progress_widget.dart';

class _WebScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class WorkflowStagesScreen extends StatefulWidget {
  final int? matterID;

  const WorkflowStagesScreen({super.key, required this.matterID});

  @override
  State<WorkflowStagesScreen> createState() => _WorkflowStagesScreenState();
}

class _WorkflowStagesScreenState extends State<WorkflowStagesScreen>
    with TickerProviderStateMixin {
  WorkflowStagesResponse? _workflowResponse;
  bool _isLoading = true;
  String? _error;

  late TabController _tabController;

  final ImagePicker _imagePicker = ImagePicker();

  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  final List<String> _tabs = ['all', 'pending', 'completed'];
  bool _stagesExpanded = false;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _stagesExpanded = false);
        _loadWorkflowData(type: _tabs[_tabController.index]);
      }
    });

    _loadWorkflowData(type: 'all');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkflowData({String type = 'all'}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getWorkflowStages(
        clientMatterId: widget.matterID ?? 0,
        type: type,
      );

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _workflowResponse = WorkflowStagesResponse.fromJson(response['data']);

          if (_workflowResponse?.activeStage != null) {
            AuthService.setClientMatterStageId(
              _workflowResponse!.activeStage!.id,
            );
          }

          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load workflow';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openUploadOptions(WorkflowStage stage, int checklistId) async {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
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
                  "Add Files",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 16),

                _buildBottomSheetOption(
                  icon: Icons.folder_open_rounded,
                  label: "My Files",
                  subtitle: "PDF, DOC, DOCX, JPG, PNG",
                  color: const Color(0xFF5B8DEF),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickFromFiles(stage, checklistId);
                  },
                ),

                const SizedBox(height: 10),

                _buildBottomSheetOption(
                  icon: Icons.photo_library_rounded,
                  label: "Gallery",
                  subtitle: "Pick from your photos",
                  color: const Color(0xFF8B5CF6),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickFromGallery(stage, checklistId);
                  },
                ),

                if (!kIsWeb) ...[
                  const SizedBox(height: 10),

                  _buildBottomSheetOption(
                    icon: Icons.camera_alt_rounded,
                    label: "Camera",
                    subtitle: "Take a new photo",
                    color: const Color(0xFF10B981),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickFromCamera(stage, checklistId);
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const Spacer(),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFromFiles(WorkflowStage stage, int checklistId) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;

      if (file.bytes == null) return;

      _selectedFileBytes = file.bytes;
      _selectedFileName = file.name;

      await _uploadDocument(stage, checklistId);
    }
  }

  Future<void> _pickFromGallery(WorkflowStage stage, int checklistId) async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      _selectedFileBytes = await image.readAsBytes();
      _selectedFileName = image.name;

      await _uploadDocument(stage, checklistId);
    }
  }

  Future<void> _pickFromCamera(WorkflowStage stage, int checklistId) async {
    final image = await _imagePicker.pickImage(source: ImageSource.camera);

    if (image != null) {
      _selectedFileBytes = await image.readAsBytes();
      _selectedFileName = image.name;

      await _uploadDocument(stage, checklistId);
    }
  }

  Future<void> _uploadDocument(WorkflowStage stage, int checklistId) async {
    if (_selectedFileBytes == null || _selectedFileName == null) return;

    _showUploadingDialog();

    try {
      final fileBytes = _selectedFileBytes!;
      final fileName = _selectedFileName!;

      final response = await ApiService.uploadWorkflowChecklistDocument(
        fileBytes: fileBytes,
        fileName: fileName,
        allowedChecklistId: checklistId,
        clientMatterId: widget.matterID ?? 0,
      );

      _hideUploadingDialog();

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Document uploaded successfully"),
            backgroundColor: Colors.green,
          ),
        );

        await _loadWorkflowData(type: _tabs[_tabController.index]);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? "Upload failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _hideUploadingDialog();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUploadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 48,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320, minWidth: 200),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(width: 24, height: 24, child: AppLoader(size: 20)),
                  SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      "Uploading document...",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onBulkUploadTap() async {
    await Navigator.pushNamed(
      context,
      '/bulk-upload-documents',
      arguments: {
        'matter_id': widget.matterID,
        'stageId': null,
        'allowedChecklistId': null,
      },
    );

    _loadWorkflowData(type: _tabs[_tabController.index]);
  }

  Future<void> _onViewTap(WorkflowStage stage, int checklistId) async {
    if (stage.allowedChecklistCount > 0) {
      Navigator.pushNamed(
        context,
        '/workflow-view-documents-by-checklist',
        arguments: {
          'matter_id': widget.matterID,
          'stageId': stage.id,
          'stageName': stage.stageName,
          'checklistId': checklistId,
        },
      );
    }
  }

  void _hideUploadingDialog() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // KEY FIX: ScrollConfiguration wraps the entire Scaffold so the scroll
    // hit-area covers 100% of the screen, not just the constrained content box.
    return ScrollConfiguration(
      behavior: _WebScrollBehavior(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),

        appBar: CommonAppBar(
          titleName: 'Workflow Stages',
          matterID: widget.matterID ?? 0,
        ),

        body: SafeArea(
          child: Column(
            children: [
              // Tab bar is visually centred but does NOT constrain the
              // scrollable area below it.
              Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppResponsive.maxContentWidth,
                  ),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: false,
                      dividerColor: Colors.transparent,
                      labelPadding: EdgeInsets.zero,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: ThemeConfig.goldenYellow,
                        boxShadow: [
                          BoxShadow(
                            color: ThemeConfig.goldenYellow.withValues(
                              alpha: 0.35,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      labelColor: ThemeConfig.navyBlue,
                      unselectedLabelColor: ThemeConfig.navyBlue.withValues(
                        alpha: 0.50,
                      ),
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                      tabs: [
                        _buildTab("All", 24),
                        _buildTab("Pending", 8),
                        _buildTab("Completed", 16),
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: _isLoading
                    ? const Center(child: AppLoader())
                    : _error != null
                    ? _buildErrorWidget(
                  _error!,
                      () => _loadWorkflowData(
                    type: _tabs[_tabController.index],
                  ),
                )
                    : _workflowResponse == null
                    ? const Center(
                  child: Text('No workflow data available'),
                )
                    : RefreshIndicator(
                  color: ThemeConfig.goldenYellow,
                  onRefresh: () => _loadWorkflowData(
                    type: _tabs[_tabController.index],
                  ),
                  // KEY FIX: SingleChildScrollView spans full
                  // screen width; content is centred via
                  // LayoutBuilder + side padding, same pattern
                  // used in the messages screen.
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final sidePadding =
                      constraints.maxWidth >
                          AppResponsive.maxContentWidth
                          ? (constraints.maxWidth -
                          AppResponsive
                              .maxContentWidth) /
                          2
                          : 0.0;

                      return SingleChildScrollView(
                        physics:
                        const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          sidePadding +
                              AppResponsive.pagePadding(context)
                                  .left,
                          AppResponsive.pagePadding(context).top,
                          sidePadding +
                              AppResponsive.pagePadding(context)
                                  .right,
                          AppResponsive.pagePadding(context)
                              .bottom,
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            if (_workflowResponse!.caseSummary !=
                                null)
                              _buildCaseSummary(
                                _workflowResponse!.caseSummary!,
                              ),

                            const SizedBox(height: 20),

                            WorkflowProgressWidget(
                              workflowResponse:
                              _workflowResponse!,
                              tabType: _tabs[_tabController.index],
                              stagesExpanded: _stagesExpanded,
                              onSeeAllTap:
                                  () => setState(() => _stagesExpanded = true),
                              onSeeLessTap:
                                  () => setState(() => _stagesExpanded = false),
                              onStageTap: _showStageDetails,
                              onChecklistPlusTap:
                              _openUploadOptions,
                              onChecklistViewTap: _onViewTap,
                              onBulkUploadTap: _onBulkUploadTap,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      height: 46,
      child: Row(mainAxisSize: MainAxisSize.min, children: [Text(label)]),
    );
  }

  Widget _buildCaseSummary(CaseSummary summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.caseName ?? '',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: ThemeConfig.navyBlue,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ThemeConfig.navyBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Status: ${summary.caseStatus ?? ''}',
              style: TextStyle(
                color: ThemeConfig.navyBlue.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: ThemeConfig.goldenYellow),

          const SizedBox(height: 16),

          Text(error, textAlign: TextAlign.center),

          const SizedBox(height: 16),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeConfig.navyBlue,
            ),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showStageDetails(WorkflowStage stage) {
    if (stage.allowedChecklistCount > 0) {
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            stage.stageName,
            style: const TextStyle(color: ThemeConfig.navyBlue),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: ${stage.statusText}'),

              if (stage.isCurrentStage)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: ThemeConfig.goldenYellow,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Current Stage',
                        style: TextStyle(
                          color: ThemeConfig.goldenYellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
}