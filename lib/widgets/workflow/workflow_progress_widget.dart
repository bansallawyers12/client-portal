import 'package:flutter/material.dart';

import '../../config/theme_config.dart';
import '../../models/workflow_stage.dart';

class WorkflowProgressWidget extends StatelessWidget {
  final WorkflowStagesResponse workflowResponse;
  final String tabType;
  final bool stagesExpanded;
  final VoidCallback? onSeeAllTap;
  final VoidCallback? onSeeLessTap;
  final Function(WorkflowStage)? onStageTap;
  final Function(WorkflowStage stage, int checklistId)? onChecklistPlusTap;
  final Function(WorkflowStage stage, int checklistId)? onChecklistViewTap;
  final Function()? onBulkUploadTap;

  const WorkflowProgressWidget({
    super.key,
    required this.workflowResponse,
    this.tabType = 'all',
    this.stagesExpanded = true,
    this.onSeeAllTap,
    this.onSeeLessTap,
    this.onStageTap,
    this.onChecklistPlusTap,
    this.onChecklistViewTap,
    this.onBulkUploadTap,
  });

  bool get _shouldCollapseStages =>
      (tabType == 'all' || tabType == 'pending') && !stagesExpanded;

  Color _getStageColor(WorkflowStage stage, BuildContext context) {
    if (stage.isCurrentStage || stage.isActive) {
      return ThemeConfig.navyBlue;
    }
    final currentIndex = workflowResponse.currentStageIndex;
    final stageIndex = workflowResponse.workflowStages.indexOf(stage);
    if (currentIndex >= 0 && stageIndex < currentIndex) {
      return const Color(0xFF22C55E);
    }
    return Colors.grey.shade300;
  }

  IconData _getStageIcon(WorkflowStage stage) {
    if (stage.isCurrentStage || stage.isActive) {
      return Icons.radio_button_checked_rounded;
    }
    final currentIndex = workflowResponse.currentStageIndex;
    final stageIndex = workflowResponse.workflowStages.indexOf(stage);
    if (currentIndex >= 0 && stageIndex < currentIndex) {
      return Icons.check_circle_rounded;
    }
    return Icons.radio_button_unchecked_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgressSummaryCard(context),
        const SizedBox(height: 20),
        _buildProgressBar(context),
        const SizedBox(height: 20),
        _buildStagesSection(context),
      ],
    );
  }

  Widget _buildProgressSummaryCard(BuildContext context) {
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
          const Text(
            'Workflow Progress',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat(
                'Completed',
                workflowResponse.completedStages.toString(),
                const Color(0xFF22C55E),
                Icons.check_circle_rounded,
              ),
              _buildStat(
                'Current',
                workflowResponse.hasActiveStage ? '1' : '0',
                const Color(0xFF3B82F6),
                Icons.pending_rounded,
              ),
              _buildStat(
                'Remaining',
                workflowResponse.remainingStages.toString(),
                const Color(0xFFF59E0B),
                Icons.pending_actions_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final progress = workflowResponse.progressPercentage;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall Progress',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              Text(
                '$progress%',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: ThemeConfig.navyBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                ThemeConfig.navyBlue,
              ),
            ),
          ),
          if (workflowResponse.hasActiveStage &&
              workflowResponse.activeStage != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Current Stage: ${workflowResponse.activeStage!.stageName}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStagesSection(BuildContext context) {
    final stages = workflowResponse.workflowStages;
    final stageCount = stages.length;

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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'All Stages',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Material(
                color: ThemeConfig.navyBlue,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: onBulkUploadTap,
                  borderRadius: BorderRadius.circular(24),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.upload_file_rounded, color: Colors.white, size: 18),
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
          const SizedBox(height: 16),
          if (stageCount == 0)
            _buildEmptyStagesState()
          else if (_shouldCollapseStages)
            _buildCollapsedStagesState(context, stageCount)
          else ...[
            ...stages.asMap().entries.map((entry) {
              final stage = entry.value;
              final isLast = entry.key == stages.length - 1;
              return _buildStageItem(context, stage, isLast);
            }),
            if ((tabType == 'all' || tabType == 'pending') && stagesExpanded)
              Center(
                child: TextButton.icon(
                  onPressed: onSeeLessTap,
                  icon: const Icon(Icons.expand_less_rounded),
                  label: const Text('Show Less'),
                  style: TextButton.styleFrom(
                    foregroundColor: ThemeConfig.navyBlue,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyStagesState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, color: Colors.grey.shade400, size: 40),
          const SizedBox(height: 10),
          Text(
            tabType == 'completed'
                ? 'No completed stages yet'
                : 'No stages to display',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedStagesState(BuildContext context, int stageCount) {
    WorkflowStage? previewStage;
    final active = workflowResponse.activeStage;
    if (active != null) {
      for (final stage in workflowResponse.workflowStages) {
        if (stage.id == active.id) {
          previewStage = stage;
          break;
        }
      }
    }
    previewStage ??=
        workflowResponse.workflowStages.isNotEmpty
            ? workflowResponse.workflowStages.first
            : null;

    return Column(
      children: [
        if (previewStage != null)
          _buildStageItem(context, previewStage, true, compact: true),
        const SizedBox(height: 12),
        Center(
          child: Material(
            color: ThemeConfig.goldenYellow.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              onTap: onSeeAllTap,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.unfold_more_rounded,
                      color: ThemeConfig.navyBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'See All ($stageCount stages)',
                      style: const TextStyle(
                        color: ThemeConfig.navyBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStageItem(
    BuildContext context,
    WorkflowStage stage,
    bool isLast, {
    bool compact = false,
  }) {
    final color = _getStageColor(stage, context);
    final icon = _getStageIcon(stage);
    final isCurrent = stage.isCurrentStage || stage.isActive;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: color == Colors.grey.shade300 ? 1 : 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: isCurrent ? 2 : 1,
                ),
              ),
              child: Icon(
                icon,
                color: color == Colors.grey.shade300 ? Colors.grey.shade600 : color,
                size: 20,
              ),
            ),
            if (!isLast && !compact)
              Container(
                width: 2,
                height: 48,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: color == Colors.grey.shade300
                    ? Colors.grey.shade300
                    : color.withValues(alpha: 0.4),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: GestureDetector(
            onTap: () => onStageTap?.call(stage),
            child: Container(
              padding: const EdgeInsets.all(14),
              margin: EdgeInsets.only(bottom: compact ? 0 : 14),
              decoration: BoxDecoration(
                color: isCurrent
                    ? ThemeConfig.navyBlue.withValues(alpha: 0.06)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCurrent ? ThemeConfig.navyBlue : Colors.grey.shade200,
                  width: isCurrent ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${stage.stageName} (${stage.allowedChecklistCount})',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isCurrent ? ThemeConfig.navyBlue : const Color(0xFF1F2937),
                    ),
                  ),
                  if (!compact && stage.allowedChecklist.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...stage.allowedChecklist.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: item.noOfDocumentUploaded == 0
                                  ? Colors.red.shade400
                                  : const Color(0xFF22C55E),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${item.name} (${item.noOfDocumentUploaded})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isCurrent
                                      ? ThemeConfig.navyBlue
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ),
                            if (item.noOfDocumentUploaded > 0)
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(
                                  Icons.remove_red_eye_outlined,
                                  color: Color(0xFF22C55E),
                                  size: 20,
                                ),
                                onPressed: () {
                                  onChecklistViewTap?.call(stage, item.id);
                                },
                              ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.add_circle_rounded,
                                color: Color(0xFF22C55E),
                                size: 20,
                              ),
                              onPressed: () {
                                onChecklistPlusTap?.call(stage, item.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Compact version for dashboard
class CompactWorkflowProgress extends StatelessWidget {
  final WorkflowStagesResponse workflowResponse;

  const CompactWorkflowProgress({super.key, required this.workflowResponse});

  @override
  Widget build(BuildContext context) {
    final progress = workflowResponse.progressPercentage;
    final currentStageName =
        workflowResponse.activeStage?.stageName ?? 'Not Started';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  currentStageName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$progress%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 4,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
