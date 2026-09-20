import 'dart:io';

import 'package:client/config/theme_config.dart';
import 'package:client/widgets/common_app_bar.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
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

class _WorkflowStagesScreenState extends State<WorkflowStagesScreen> {
  WorkflowStagesResponse? _workflowResponse;
  bool _isLoading = true;
  String? _error;

  final ImagePicker _imagePicker = ImagePicker();

  Uint8List? _selectedFileBytes;
  String? _selectedFileName;

  @override
  void initState() {
    super.initState();
    _loadWorkflowData();
  }

  Future<void> _loadWorkflowData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getWorkflowStages(
        clientMatterId: widget.matterID ?? 0,
        type: 'all',
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
                    icon: Icons.document_scanner_rounded,
                    label: "Scan Documents",
                    subtitle: "Auto-crop & capture pages as PDF",
                    color: const Color(0xFF10B981),
                    onTap: () async {
                      Navigator.pop(context);
                      await _scanDocuments(stage, checklistId);
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
          content: Text("Scan failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
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

        await _loadWorkflowData();
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

  Future<void> _onViewTap(WorkflowStage stage, int checklistId) async {
    if (stage.allowedChecklistCount > 0) {
      Navigator.pushNamed(
        context,
        '/workflow-view-documents-by-checklist',
        arguments: {
          'matter_id': widget.matterID,
          'stageId': stage.id,
          'stageName': stage.displayName,
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
    return ScrollConfiguration(
      behavior: _WebScrollBehavior(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        appBar: CommonAppBar(
          titleName: 'Workflow Stages',
          matterID: widget.matterID ?? 0,
        ),
        body: SafeArea(
          child: _isLoading
              ? const Center(child: AppLoader())
              : _error != null
              ? _buildErrorWidget(_error!, _loadWorkflowData)
              : _workflowResponse == null
              ? const Center(child: Text('No workflow data available'))
              : RefreshIndicator(
                color: ThemeConfig.goldenYellow,
                onRefresh: _loadWorkflowData,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final sidePadding =
                        constraints.maxWidth > AppResponsive.maxContentWidth
                            ? (constraints.maxWidth -
                                    AppResponsive.maxContentWidth) /
                                2
                            : 0.0;

                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        sidePadding +
                            AppResponsive.pagePadding(context).left,
                        AppResponsive.pagePadding(context).top,
                        sidePadding +
                            AppResponsive.pagePadding(context).right,
                        AppResponsive.pagePadding(context).bottom,
                      ),
                      child: WorkflowProgressWidget(
                        workflowResponse: _workflowResponse!,
                        tabType: 'all',
                        stagesExpanded: true,
                        onSeeAllTap: null,
                        onSeeLessTap: null,
                        onStageTap: _showStageDetails,
                        onChecklistPlusTap: _openUploadOptions,
                        onChecklistViewTap: _onViewTap,
                        onBulkUploadTap: null,
                      ),
                    );
                  },
                ),
              ),
        ),
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
            stage.displayName,
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