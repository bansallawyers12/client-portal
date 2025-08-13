import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/case.dart';

// Timeline event model
class TimelineEvent {
  final String title;
  final String description;
  final DateTime date;
  final TimelineEventType type;

  TimelineEvent({
    required this.title,
    required this.description,
    required this.date,
    required this.type,
  });
}

enum TimelineEventType { created, document, task, milestone, update }

class TimelineWidget extends StatelessWidget {
  final List<TimelineEvent> events;

  const TimelineWidget({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No timeline events yet',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final isLast = index == events.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line and dot
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getEventTypeColor(event.type),
                  ),
                ),
                if (!isLast)
                  Container(width: 2, height: 60, color: Colors.grey.shade300),
              ],
            ),

            const SizedBox(width: 16),

            // Event content
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getEventTypeIcon(event.type),
                          color: _getEventTypeColor(event.type),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            event.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getEventTypeColor(
                              event.type,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getEventTypeLabel(event.type),
                            style: TextStyle(
                              color: _getEventTypeColor(event.type),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      event.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM dd, yyyy HH:mm').format(event.date),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade500),
                        ),

                        const Spacer(),

                        if (event.type == TimelineEventType.document)
                          TextButton.icon(
                            onPressed: () {
                              // TODO: Navigate to document details
                            },
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('View'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),

                        if (event.type == TimelineEventType.task)
                          TextButton.icon(
                            onPressed: () {
                              // TODO: Navigate to task details
                            },
                            icon: const Icon(Icons.task, size: 16),
                            label: const Text('View Task'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getEventTypeColor(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.created:
        return Colors.blue;
      case TimelineEventType.document:
        return Colors.green;
      case TimelineEventType.task:
        return Colors.orange;
      case TimelineEventType.milestone:
        return Colors.purple;
      case TimelineEventType.update:
        return Colors.teal;
    }
  }

  IconData _getEventTypeIcon(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.created:
        return Icons.add_circle;
      case TimelineEventType.document:
        return Icons.description;
      case TimelineEventType.task:
        return Icons.task;
      case TimelineEventType.milestone:
        return Icons.flag;
      case TimelineEventType.update:
        return Icons.update;
    }
  }

  String _getEventTypeLabel(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.created:
        return 'CREATED';
      case TimelineEventType.document:
        return 'DOCUMENT';
      case TimelineEventType.task:
        return 'TASK';
      case TimelineEventType.milestone:
        return 'MILESTONE';
      case TimelineEventType.update:
        return 'UPDATE';
    }
  }
}
