import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../config/theme_config.dart';
import '../../models/workflow_checklist.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_loader.dart';
import '../../utils/app_logger.dart';
import '../../utils/responsive_utils.dart';

class WorkflowDocumentsScreen extends StatefulWidget {
  final int? stageId;
  final String? stageName;

  const WorkflowDocumentsScreen({super.key, this.stageId, this.stageName});

  @override
  State<WorkflowDocumentsScreen> createState() =>
      _WorkflowDocumentsScreenState();
}

class _WorkflowDocumentsScreenState extends State<WorkflowDocumentsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  WorkflowChecklistResponse? _checklistResponse;
  final Map<int, bool> _uploadingStates = {};

  @override
  void initState() {
    super.initState();
    _loadChecklistData();
  }

  Future<void> _loadChecklistData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getWorkflowAllowedChecklist(
        clientMatterId: AuthService.selectedMatterId ?? 0,
        stageId: widget.stageId,
      );
      final responseJsonString = jsonEncode(response);
      AppLogger.info(
        'Workflow Allowed Checklist Response: $responseJsonString',
      );
      if (response['success'] == true && response['data'] != null) {
        _checklistResponse = WorkflowChecklistResponse.fromJson(
          response['data'],
        );
      } else {
        _errorMessage = response['message'] ?? 'Failed to load checklist';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadDocument(WorkflowChecklist checklist) async {
    setState(() => _uploadingStates[checklist.id] = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.single;
      if (pickedFile.bytes == null) return;

      final response = await ApiService.uploadWorkflowChecklistDocument(
        fileBytes: pickedFile.bytes!,
        fileName: pickedFile.name,
        allowedChecklistId: checklist.id,
        clientMatterId: AuthService.selectedMatterId ?? 0,
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Upload successful')));
        _loadChecklistData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Upload failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      setState(() => _uploadingStates[checklist.id] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    String stageName = widget.stageName ?? "Document";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          stageName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        elevation: 4,
        backgroundColor: ThemeConfig.goldenYellow,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppResponsive.maxContentWidth,
            ),
            child: content,
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "bulkUpload",
            backgroundColor: ThemeConfig.goldenYellow,
            elevation: 6,
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/bulk-upload-documents',
                arguments: {
                  'matter_id': AuthService.selectedMatterId,
                },
              );
            },
            icon: const Icon(Icons.upload_file, color: Colors.white),
            label: const Text(
              "Bulk Upload",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: "singleUpload",
            backgroundColor: ThemeConfig.goldenYellow,
            elevation: 6,
            onPressed: () {
              Navigator.pushNamed(context, '/upload-documents');
            },
            icon: const Icon(Icons.upload_file, color: Colors.white),
            label: const Text(
              "Upload Document",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: AppLoader());
    }

    if (_errorMessage != null) {
      return _buildErrorWidget(_errorMessage!, _loadChecklistData);
    }

    if (_checklistResponse == null ||
        _checklistResponse!.allowedChecklists.isEmpty) {
      return const Center(child: Text('No documents required.'));
    }

    return RefreshIndicator(
      onRefresh: _loadChecklistData,
      child: ListView(
        padding: AppResponsive.pagePadding(context),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          ..._checklistResponse!.allowedChecklists.map(_buildChecklistItem),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(WorkflowChecklist checklist) {
    final isUploading = _uploadingStates[checklist.id] ?? false;

    Color statusColor;
    String statusText;

    if (checklist.docStatusId == 0) {
      statusColor = Colors.blue;
      statusText = checklist.docStatusText ?? "In progress";
    } else if (checklist.docStatusId == 1) {
      statusColor = Colors.green;
      statusText = checklist.docStatusText ?? "Approved";
    } else if (checklist.docStatusId == 2) {
      statusColor = Colors.red;
      statusText = checklist.docStatusText ?? "Rejected";
    } else {
      statusColor = Colors.grey;
      statusText = checklist.docStatusText ?? "Not uploaded";
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              checklist.checklistName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 4),

            if (checklist.typeName != null && checklist.typeName!.isNotEmpty)
              Text(
                checklist.typeName!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                border: Border.all(color: statusColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),

            if (checklist.docRejectionReason != null &&
                checklist.docRejectionReason!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  "Reason: ${checklist.docRejectionReason}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // Upload / View section
            if (checklist.isUpload && checklist.fileUrl != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      checklist.fileName ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/pdf-viewer',
                        arguments: {
                          'url': checklist.fileUrl,
                          'title': checklist.fileName,
                        },
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('View'),
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed:
                    isUploading ? null : () => _uploadDocument(checklist),
                icon:
                    isUploading
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: AppLoader(),
                        )
                        : const Icon(Icons.upload_file),
                label: Text(isUploading ? 'Uploading...' : 'Upload Document'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Documents Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildChip(
                  'Total',
                  _checklistResponse!.totalAllowedChecklists.toString(),
                  Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildChip(
                  'Required',
                  _checklistResponse!.mandatoryChecklists.toString(),
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, String value, Color color) {
    return Chip(
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color),
      label: Text(
        '$label: $value',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
