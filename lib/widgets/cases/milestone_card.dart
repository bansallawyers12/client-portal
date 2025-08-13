import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MilestoneCard extends StatelessWidget {
  final String title;
  final String description;
  final DateTime date;
  final bool isCompleted;
  final bool isCurrent;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const MilestoneCard({
    super.key,
    required this.title,
    required this.description,
    required this.date,
    this.isCompleted = false,
    this.isCurrent = false,
    this.icon = Icons.flag,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final milestoneColor = color ?? theme.primaryColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isCurrent
                      ? milestoneColor
                      : isCompleted
                      ? Colors.green
                      : Colors.grey.shade200,
              width: isCurrent ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Milestone icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color:
                      isCompleted
                          ? Colors.green
                          : isCurrent
                          ? milestoneColor
                          : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),

              const SizedBox(width: 16),

              // Milestone content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color:
                                  isCompleted
                                      ? Colors.green
                                      : isCurrent
                                      ? milestoneColor
                                      : theme.textTheme.titleMedium?.color,
                            ),
                          ),
                        ),

                        // Status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isCompleted
                                    ? Colors.green.withOpacity(0.1)
                                    : isCurrent
                                    ? milestoneColor.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isCompleted
                                ? 'COMPLETED'
                                : isCurrent
                                ? 'CURRENT'
                                : 'PENDING',
                            style: TextStyle(
                              color:
                                  isCompleted
                                      ? Colors.green
                                      : isCurrent
                                      ? milestoneColor
                                      : Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd, yyyy').format(date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                        ),

                        if (isCompleted) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Completed',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Action button
              if (onTap != null)
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
