import 'package:flutter/material.dart';

import '../../../config/client_stage_mapping.dart';
import '../../../config/theme_config.dart';
import '../../../models/workflow_stage.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_loader.dart';
import '../../../utils/responsive_utils.dart';
import 'my_files_quick_action_card.dart';

class MyFilesScreen extends StatefulWidget {
  const MyFilesScreen({super.key});

  @override
  State<MyFilesScreen> createState() => _MyFilesScreenState();
}

class _MyFilesScreenState extends State<MyFilesScreen> {
  WorkflowStagesResponse? _workflow;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWorkflow();
  }

  Future<void> _loadWorkflow() async {
    if (!AuthService.isAuthenticated || !AuthService.isMatterSelected) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = null;
          _workflow = null;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getWorkflowStages(
        clientMatterId: AuthService.selectedMatterId,
        type: 'all',
      );
      if (!mounted) return;

      final data = response['data'] ?? response;
      if (data is Map) {
        setState(() {
          _workflow = WorkflowStagesResponse.fromJson(
            Map<String, dynamic>.from(data),
          );
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message']?.toString() ?? 'Failed to load matter';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _openDocuments() {
    Navigator.pushNamed(context, '/documents');
  }

  @override
  Widget build(BuildContext context) {
    final stageName = _workflow?.currentDisplayName;
    final progress = _workflow?.progressPercentage ?? 0;
    final matterNo = _workflow?.activeStage?.clientMatterNo;
    final statusTag = _workflow?.currentStatusTag;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'My Files',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: ThemeConfig.goldenYellow,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: ThemeConfig.goldenYellow,
          onRefresh: _loadWorkflow,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppResponsive.maxContentWidth,
              ),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppResponsive.pagePadding(context),
                children: [
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: AppLoader()),
                    )
                  else ...[
                    MyFilesQuickActionsCard(
                      currentStageName:
                          (stageName != null && stageName.isNotEmpty)
                              ? stageName
                              : null,
                      progressPercent: progress,
                      matterNumber: matterNo,
                      statusTagLabel: statusTag?.label,
                      statusTagColor: statusTag?.foreground,
                      statusTagBackground: statusTag?.background,
                      onViewWorkflow: () {
                        Navigator.pushNamed(
                          context,
                          '/workflow-stages',
                          arguments: {
                            'matter_id': AuthService.selectedMatterId,
                          },
                        );
                      },
                      onMyFiles: _openDocuments,
                      onBilling: () {
                        Navigator.pushNamed(
                          context,
                          '/billing-list',
                          arguments: {
                            'matter_id': AuthService.selectedMatterId,
                          },
                        );
                      },
                      onMessage: () {
                        Navigator.pushNamed(
                          context,
                          '/workflow-message',
                          arguments: {
                            'matter_id': AuthService.selectedMatterId,
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      _errorCard(_error!, _loadWorkflow)
                    else
                      _documentsEntryCard(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _documentsEntryCard() {
    final checklistCount =
        _workflow?.currentStage?.allowedChecklistCount ?? 0;
    final completed = _workflow?.completedStages ?? 0;
    final remaining = _workflow?.remainingStages ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
          const Text(
            'DOCUMENTS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: Color(0xFF7A8794),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniStat('Completed', '$completed', const Color(0xFF22C55E)),
              _miniStat('Current tasks', '$checklistCount', ThemeConfig.navyBlue),
              _miniStat('Remaining', '$remaining', const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openDocuments,
              icon: const Icon(Icons.folder_open_rounded),
              label: const Text('Open documents'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeConfig.navyBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/bulk-upload-documents',
                  arguments: {
                    'matter_id': AuthService.selectedMatterId,
                  },
                );
              },
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Bulk Upload'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ThemeConfig.navyBlue,
                side: const BorderSide(color: ThemeConfig.navyBlue),
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF7A8794),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String error, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E7ED)),
      ),
      child: Column(
        children: [
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
