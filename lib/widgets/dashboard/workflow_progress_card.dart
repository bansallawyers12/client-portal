import 'package:flutter/material.dart';
import '../../models/workflow_stage.dart';
import '../../utils/app_loader.dart';

class WorkflowProgressCard extends StatelessWidget {
  final WorkflowStagesResponse? workflowResponse;
  final bool isLoading;
  final VoidCallback? onTap;

  const WorkflowProgressCard({
    super.key,
    this.workflowResponse,
    this.isLoading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoadingCard(context);
    if (workflowResponse == null) return const SizedBox.shrink();

    final progress = workflowResponse!.progressPercentage;
    final currentStageName =
        workflowResponse!.currentDisplayName.isNotEmpty
            ? workflowResponse!.currentDisplayName
            : 'Not Started';
    final hasActiveStage = workflowResponse!.hasActiveStage;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF283593)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.1), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.timeline, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Case Progress',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Current Workflow Status',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
              ],
            ),
            const SizedBox(height: 12),

            // Current Stage Info
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha:0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9B000).withValues(alpha:0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      hasActiveStage ? Icons.pending_actions : Icons.help_outline,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Stage', style: TextStyle(color: Colors.white70, fontSize: 9)),
                        const SizedBox(height: 2),
                        Text(
                          currentStageName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Overall Progress', style: TextStyle(color: Colors.white70, fontSize: 10)),
                    Text('$progress%', style: const TextStyle(color: Color(0xFFF9B000), fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 6),
                Stack(
                  children: [
                    Container(height: 6, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3))),
                    FractionallySizedBox(
                      widthFactor: progress / 100,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFF9B000), Color(0xFFFFD54F)]),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stats Row
            Row(
              children: [
                _buildStatChip(context, icon: Icons.check_circle, label: 'Completed', value: workflowResponse!.completedStages.toString(), color: Colors.green),
                const SizedBox(width: 6),
                _buildStatChip(context, icon: Icons.hourglass_empty, label: 'Remaining', value: workflowResponse!.remainingStages.toString(), color: Colors.orange),
                const SizedBox(width: 6),
                _buildStatChip(context, icon: Icons.list_alt, label: 'Total', value: workflowResponse!.totalStages.toString(), color: Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(BuildContext context,
      {required IconData icon, required String label, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha:0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF283593)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: const [
          SizedBox(height: 4),
          AppLoader(),
          SizedBox(height: 8),
          Text('Loading workflow progress...', style: TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}
