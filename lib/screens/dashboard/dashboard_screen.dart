import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/case.dart';
import '../../models/document.dart';
import '../../models/appointment.dart';
import '../../models/task.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/dashboard/case_summary_card.dart';
import '../../widgets/dashboard/document_status_card.dart';
import '../../widgets/dashboard/upcoming_deadlines_card.dart';
import '../../widgets/dashboard/quick_actions_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  // Mock data for demonstration - replace with actual API calls
  List<Case> _cases = [];
  List<Document> _documents = [];
  List<Appointment> _appointments = [];
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Replace with actual API calls
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      // Load mock data
      _loadMockData();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load dashboard data: ${e.toString()}';
      });
    }
  }

  void _loadMockData() {
    // Mock cases
    _cases = [
      Case(
        id: 1,
        name: 'Immigration Visa Application',
        status: 'in_progress',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Case(
        id: 2,
        name: 'Work Permit Renewal',
        status: 'pending_documents',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Case(
        id: 3,
        name: 'Citizenship Application',
        status: 'completed',
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];

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
        title: 'Birth Certificate',
        status: 'pending_review',
        uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Document(
        id: 3,
        title: 'Employment Letter',
        status: 'rejected',
        uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    // Mock appointments
    _appointments = [
      Appointment(
        id: 1,
        title: 'Visa Interview',
        date: DateTime.now().add(const Duration(days: 3)),
        time: '10:00 AM',
        status: 'confirmed',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Appointment(
        id: 2,
        title: 'Document Review',
        date: DateTime.now().add(const Duration(days: 7)),
        time: '2:00 PM',
        status: 'pending',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    // Mock tasks
    _tasks = [
      Task(
        id: 1,
        title: 'Submit additional documents',
        dueDate: DateTime.now().add(const Duration(days: 5)),
        priority: 'high',
        status: 'pending',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Task(
        id: 2,
        title: 'Schedule medical examination',
        dueDate: DateTime.now().add(const Duration(days: 10)),
        priority: 'medium',
        status: 'in_progress',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              // TODO: Navigate to profile
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const LoadingWidget(message: 'Loading dashboard...')
              : _errorMessage != null
              ? CustomErrorWidget(
                message: _errorMessage!,
                onRetry: _loadDashboardData,
              )
              : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Welcome Section
                      _buildWelcomeSection(),
                      const SizedBox(height: 24),

                      // Quick Actions
                      QuickActionsCard(
                        onUploadDocument: () {
                          // TODO: Navigate to document upload
                        },
                        onBookAppointment: () {
                          // TODO: Navigate to appointment booking
                        },
                        onSendMessage: () {
                          // TODO: Navigate to messaging
                        },
                      ),
                      const SizedBox(height: 24),

                      // Case Summary
                      CaseSummaryCard(cases: _cases),
                      const SizedBox(height: 24),

                      // Document Status
                      DocumentStatusCard(documents: _documents),
                      const SizedBox(height: 24),

                      // Upcoming Deadlines
                      UpcomingDeadlinesCard(
                        tasks: _tasks,
                        appointments: _appointments,
                      ),
                      const SizedBox(height: 24),

                      // Recent Activity
                      _buildRecentActivitySection(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Here\'s what\'s happening with your cases',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatItem(
                icon: Icons.folder_open,
                label: 'Active Cases',
                value:
                    _cases
                        .where((c) => c.status != 'completed')
                        .length
                        .toString(),
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                icon: Icons.description,
                label: 'Documents',
                value: _documents.length.toString(),
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                icon: Icons.schedule,
                label: 'Appointments',
                value: _appointments.length.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to full activity log
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            icon: Icons.upload_file,
            title: 'Document uploaded',
            subtitle: 'Passport copy uploaded for Case #123',
            time: '2 hours ago',
            color: Colors.blue,
          ),
          _buildActivityItem(
            icon: Icons.schedule,
            title: 'Appointment scheduled',
            subtitle: 'Visa interview scheduled for Dec 15',
            time: '1 day ago',
            color: Colors.green,
          ),
          _buildActivityItem(
            icon: Icons.message,
            title: 'Message received',
            subtitle: 'New message from your case manager',
            time: '2 days ago',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
