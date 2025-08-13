import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final int currentStage;
  final int totalStages;
  final double progress;
  final double height;
  final Color? activeColor;
  final Color? inactiveColor;

  const ProgressBar({
    super.key,
    required this.currentStage,
    required this.totalStages,
    required this.progress,
    this.height = 8.0,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = this.activeColor ?? theme.primaryColor;
    final inactiveColor = this.inactiveColor ?? theme.dividerColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        Container(
          height: height,
          decoration: BoxDecoration(
            color: inactiveColor,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Stage indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(totalStages, (index) {
            final stageNumber = index + 1;
            final isCompleted = stageNumber <= currentStage;
            final isCurrent = stageNumber == currentStage;

            return Expanded(
              child: Row(
                children: [
                  // Stage circle
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted ? activeColor : inactiveColor,
                      border:
                          isCurrent && !isCompleted
                              ? Border.all(color: activeColor, width: 2)
                              : null,
                    ),
                    child: Center(
                      child:
                          isCompleted
                              ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                              : Text(
                                stageNumber.toString(),
                                style: TextStyle(
                                  color: isCurrent ? activeColor : Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),

                  // Connector line (except for last stage)
                  if (stageNumber < totalStages)
                    Expanded(
                      child: Container(
                        height: 2,
                        color:
                            stageNumber < currentStage
                                ? activeColor
                                : inactiveColor,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),

        const SizedBox(height: 8),

        // Stage labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStageLabel('Created', 1),
            _buildStageLabel('Documents', 2),
            _buildStageLabel('In Progress', 3),
            _buildStageLabel('Review', 4),
            _buildStageLabel('Completed', 5),
          ],
        ),
      ],
    );
  }

  Widget _buildStageLabel(String label, int stage) {
    final isCompleted = stage <= currentStage;
    final isCurrent = stage == currentStage;

    return Expanded(
      child: Builder(
        builder:
            (context) => Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isCurrent || isCompleted
                        ? FontWeight.w600
                        : FontWeight.normal,
                color:
                    isCompleted
                        ? Colors.green
                        : isCurrent
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
              ),
            ),
      ),
    );
  }
}
