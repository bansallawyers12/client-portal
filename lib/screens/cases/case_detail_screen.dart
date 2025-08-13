import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/case.dart';
import '../../models/document.dart';
import '../../models/task.dart';
import '../../models/note.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/cases/progress_bar.dart';
import '../../widgets/cases/timeline_widget.dart';
import '../../widgets/cases/milestone_card.dart';

class CaseDetailScreen extends StatefulWidget {
  final int caseId;

  const CaseDetailScreen({super.key, required this.caseId});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  Case? _case;
  List<Document> _documents = [];
  List<Task> _tasks = [];
  List<Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCaseDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCaseDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Replace with actual API calls
      await Future.delayed(const Duration(seconds: 1));

      _loadMockData();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load case details: ${e.toString()}';
      });
    }
  }

  void _loadMockData() {
    // Mock case data
    _case = Case(
      id: widget.caseId,
      name: 'Student Visa Application',
      status: 'in_progress',
      caseType: 'Student Visa',
      priority: 'high',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      estimatedCompletion: DateTime.now().add(const Duration(days: 7)),
      description:
          'Processing student visa application for University of Melbourne. This is a comprehensive application requiring multiple document submissions and interviews.',
    );

    // Mock documents
    _documents = [
      Document(
        id: 1,
        title: 'Passport Copy',
        status: 'approved',
        uploadedAt: DateTime.now().subtract(const Duration(days: 5)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Document(
        id: 2,
        title: 'Academic Transcripts',
        status: 'pending_review',
        uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Document(
        id: 3,
        title: 'Financial Statements',
        status: 'rejected',
        uploadedAt: DateTime.now().subtract(const Duration(days: 7)),
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ];

    // Mock tasks
    _tasks = [
      Task(
        id: 1,
        title: 'Submit additional financial documents',
        description:
            'Please provide updated bank statements for the last 6 months',
        status: 'pending',
        priority: 'high',
        dueDate: DateTime.now().add(const Duration(days: 3)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      Task(
        id: 2,
        title: 'Schedule interview appointment',
        description: 'Book an appointment for visa interview',
        status: 'completed',
        priority: 'medium',
        dueDate: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    // Mock notes
    _notes = [
      Note(
        id: 1,
        title: 'Document review completed',
        description:
            'Initial document review completed. Financial statements need to be updated with recent transactions.',
        type: 'update',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
      Note(
        id: 2,
        title: 'Interview scheduled',
        description:
            'Visa interview scheduled for next week. Client has been notified.',
        type: 'milestone',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingWidget());
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Case Details')),
        body: CustomErrorWidget(
          message: _errorMessage!,
          onRetry: _loadCaseDetails,
        ),
      );
    }

    if (_case == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Case Details')),
        body: const Center(child: Text('Case not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Case #${_case!.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Implement more options menu
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Case header with progress
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _case!.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(_case!.status ?? ''),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (_case!.status ?? '')
                            .replaceAll('_', ' ')
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(_case!.priority ?? ''),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (_case!.priority ?? '').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ProgressBar(
                  currentStage: _getCurrentStage(),
                  totalStages: 5,
                  progress: _getProgressPercentage(),
                ),
                const SizedBox(height: 16),
                Text(
                  _case!.description ?? 'No description available',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),

          // Tab bar
          Container(
            color: Theme.of(context).cardColor,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Documents'),
                Tab(text: 'Tasks'),
                Tab(text: 'Timeline'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildDocumentsTab(),
                _buildTasksTab(),
                _buildTimelineTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Case information card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Case Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Case Type', _case!.caseType ?? 'N/A'),
                  _buildInfoRow('Priority', _case!.priority ?? 'N/A'),
                  _buildInfoRow(
                    'Created',
                    DateFormat('MMM dd, yyyy').format(_case!.createdAt),
                  ),
                  _buildInfoRow(
                    'Last Updated',
                    DateFormat('MMM dd, yyyy').format(_case!.updatedAt),
                  ),
                  if (_case!.estimatedCompletion != null)
                    _buildInfoRow(
                      'Estimated Completion',
                      DateFormat(
                        'MMM dd, yyyy',
                      ).format(_case!.estimatedCompletion!),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quick stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Documents',
                  '${_documents.length}',
                  Icons.description,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Tasks',
                  '${_tasks.length}',
                  Icons.task,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Notes',
                  '${_notes.length}',
                  Icons.note,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Recent activity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_notes.isNotEmpty)
                    ..._notes.take(3).map((note) => _buildActivityItem(note)),
                  if (_notes.isEmpty) const Text('No recent activity'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final document = _documents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getDocumentStatusColor(document.status),
              child: Icon(
                _getDocumentIcon(document.status),
                color: Colors.white,
              ),
            ),
            title: Text(document.title ?? 'Untitled'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${document.status?.replaceAll('_', ' ')}'),
                if (document.uploadedAt != null)
                  Text(
                    'Uploaded: ${DateFormat('MMM dd, yyyy').format(document.uploadedAt!)}',
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                // TODO: Implement document actions
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(value: 'view', child: Text('View')),
                    const PopupMenuItem(
                      value: 'download',
                      child: Text('Download'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTasksTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getTaskStatusColor(task.status),
              child: Icon(_getTaskIcon(task.status), color: Colors.white),
            ),
            title: Text(task.title ?? 'Untitled'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.description ?? 'No description'),
                Text(
                  'Due Date: ${DateFormat('MMM dd, yyyy').format(task.dueDate ?? DateTime.now())}',
                ),
                Text('Priority: ${task.priority ?? 'N/A'}'),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                // TODO: Implement task actions
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'complete',
                      child: Text('Mark Complete'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineTab() {
    return TimelineWidget(events: _buildTimelineEvents());
  }

  List<TimelineEvent> _buildTimelineEvents() {
    final events = <TimelineEvent>[];

    // Add case creation
    events.add(
      TimelineEvent(
        title: 'Case Created',
        description: 'Case was created and assigned',
        date: _case!.createdAt,
        type: TimelineEventType.created,
      ),
    );

    // Add document uploads
    for (final doc in _documents) {
      if (doc.uploadedAt != null) {
        events.add(
          TimelineEvent(
            title: 'Document Uploaded: ${doc.title}',
            description: 'Document was uploaded and is ${doc.status}',
            date: doc.uploadedAt!,
            type: TimelineEventType.document,
          ),
        );
      }
    }

    // Add task completions
    for (final task in _tasks) {
      if (task.status == 'completed') {
        events.add(
          TimelineEvent(
            title: 'Task Completed: ${task.title}',
            description: 'Task was marked as complete',
            date: task.updatedAt,
            type: TimelineEventType.task,
          ),
        );
      }
    }

    // Sort by date
    events.sort((a, b) => b.date.compareTo(a.date));

    return events;
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Note note) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _getNoteTypeColor(note.type),
            child: Icon(
              _getNoteTypeIcon(note.type),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title ?? 'No title',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  note.description ?? 'No description',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(note.createdAt),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;

    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'pending_documents':
        return Colors.red;
      case 'under_review':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getDocumentStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending_review':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getDocumentIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'pending_review':
        return Icons.pending;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.description;
    }
  }

  Color _getTaskStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTaskIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.play_circle;
      case 'pending':
        return Icons.schedule;
      default:
        return Icons.task;
    }
  }

  Color _getNoteTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'milestone':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getNoteTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'milestone':
        return Icons.flag;
      case 'update':
        return Icons.info;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      default:
        return Icons.note;
    }
  }

  int _getCurrentStage() {
    switch (_case!.status.toLowerCase()) {
      case 'completed':
        return 5;
      case 'in_progress':
        return 3;
      case 'pending_documents':
        return 2;
      case 'under_review':
        return 4;
      default:
        return 1;
    }
  }

  double _getProgressPercentage() {
    return _getCurrentStage() / 5.0;
  }
}
