import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/task.dart';
import '../../services/api_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Task> tasks = [];
  bool isLoading = true;
  String? error;
  String selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // TODO: Replace with actual API call when backend is ready
      // final data = await ApiService.getTasks();

      // Mock data for now
      await Future.delayed(Duration(milliseconds: 800));
      final mockTasks = [
        Task(
          id: 1,
          title: 'Submit Passport Copy',
          description: 'Please upload a clear copy of your passport bio page',
          status: 'pending',
          priority: 'high',
          assignedTo: 1,
          dueDate: DateTime.now().add(Duration(days: 3)),
          createdAt: DateTime.now().subtract(Duration(days: 5)),
          updatedAt: DateTime.now().subtract(Duration(hours: 2)),
          notes: 'Required for visa application processing',
          tags: ['document', 'urgent'],
        ),
        Task(
          id: 2,
          title: 'Complete Medical Examination',
          description:
              'Schedule and complete medical examination at approved clinic',
          status: 'in_progress',
          priority: 'medium',
          assignedTo: 1,
          dueDate: DateTime.now().add(Duration(days: 14)),
          createdAt: DateTime.now().subtract(Duration(days: 10)),
          updatedAt: DateTime.now().subtract(Duration(days: 1)),
          notes: 'Medical examination required for student visa',
          tags: ['medical', 'health'],
        ),
        Task(
          id: 3,
          title: 'Provide Financial Documents',
          description: 'Submit bank statements and financial support documents',
          status: 'completed',
          priority: 'high',
          assignedTo: 1,
          dueDate: DateTime.now().subtract(Duration(days: 2)),
          createdAt: DateTime.now().subtract(Duration(days: 15)),
          updatedAt: DateTime.now().subtract(Duration(days: 2)),
          notes: 'Financial documents submitted and approved',
          tags: ['financial', 'completed'],
        ),
        Task(
          id: 4,
          title: 'English Language Test',
          description: 'Take IELTS or equivalent English proficiency test',
          status: 'pending',
          priority: 'medium',
          assignedTo: 1,
          dueDate: DateTime.now().add(Duration(days: 21)),
          createdAt: DateTime.now().subtract(Duration(days: 8)),
          updatedAt: DateTime.now().subtract(Duration(days: 3)),
          notes: 'Minimum score of 6.5 required',
          tags: ['english', 'test'],
        ),
      ];

      setState(() {
        tasks = mockTasks;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  List<Task> get filteredTasks {
    switch (selectedFilter) {
      case 'pending':
        return tasks.where((task) => task.status == 'pending').toList();
      case 'in_progress':
        return tasks.where((task) => task.status == 'in_progress').toList();
      case 'completed':
        return tasks.where((task) => task.status == 'completed').toList();
      case 'overdue':
        return tasks
            .where(
              (task) =>
                  task.status != 'completed' &&
                  task.dueDate != null &&
                  task.dueDate!.isBefore(DateTime.now()),
            )
            .toList();
      default:
        return tasks;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF27AE60);
      case 'in_progress':
        return const Color(0xFF3498DB);
      case 'pending':
        return const Color(0xFFF39C12);
      case 'overdue':
        return const Color(0xFFE74C3C);
      default:
        return const Color(0xFFB0B7C3);
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFE74C3C);
      case 'medium':
        return const Color(0xFFF39C12);
      case 'low':
        return const Color(0xFF27AE60);
      default:
        return const Color(0xFFB0B7C3);
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In Progress';
      case 'pending':
        return 'Pending';
      case 'overdue':
        return 'Overdue';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays < 0) {
      return '${difference.inDays.abs()} days ago';
    } else {
      return '${difference.inDays} days';
    }
  }

  bool _isOverdue(Task task) {
    return task.status != 'completed' &&
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Tasks',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to task creation screen
                  },
                  icon: Icon(Icons.add, size: 18),
                  label: Text('New Task'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5E8B7E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Task statistics
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFE3E8EF)),
              ),
              child: Row(
                children: [
                  _buildStatCard(
                    'Total Tasks',
                    tasks.length.toString(),
                    Icons.task,
                  ),
                  SizedBox(width: 24),
                  _buildStatCard(
                    'Pending',
                    tasks.where((t) => t.status == 'pending').length.toString(),
                    Icons.pending,
                  ),
                  SizedBox(width: 24),
                  _buildStatCard(
                    'In Progress',
                    tasks
                        .where((t) => t.status == 'in_progress')
                        .length
                        .toString(),
                    Icons.work,
                  ),
                  SizedBox(width: 24),
                  _buildStatCard(
                    'Overdue',
                    tasks.where((t) => _isOverdue(t)).length.toString(),
                    Icons.warning,
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Filter tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All Tasks'),
                  SizedBox(width: 12),
                  _buildFilterChip('pending', 'Pending'),
                  SizedBox(width: 12),
                  _buildFilterChip('in_progress', 'In Progress'),
                  SizedBox(width: 12),
                  _buildFilterChip('completed', 'Completed'),
                  SizedBox(width: 12),
                  _buildFilterChip('overdue', 'Overdue'),
                ],
              ),
            ),

            SizedBox(height: 24),

            if (isLoading)
              Center(child: CircularProgressIndicator())
            else if (error != null)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text('Error: $error'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _fetchTasks,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (filteredTasks.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.task_alt, size: 64, color: Color(0xFFB0B7C3)),
                    SizedBox(height: 16),
                    Text(
                      'No tasks found',
                      style: TextStyle(fontSize: 18, color: Color(0xFF5E8B7E)),
                    ),
                    SizedBox(height: 8),
                    Text(
                      selectedFilter == 'all'
                          ? 'You have no tasks assigned yet'
                          : 'No tasks match the selected filter',
                      style: TextStyle(fontSize: 14, color: Color(0xFFB0B7C3)),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    final isOverdue = _isOverdue(task);

                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          // TODO: Navigate to task detail screen
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border:
                                isOverdue
                                    ? Border.all(
                                      color: Color(0xFFE74C3C),
                                      width: 2,
                                    )
                                    : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task.title ?? 'Untitled Task',
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF30475E),
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            task.description ??
                                                'No description',
                                            style: GoogleFonts.inter(
                                              fontSize: 14,
                                              color: Color(0xFF5E8B7E),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                              task.status ?? 'pending',
                                            ).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: Text(
                                            _getStatusText(
                                              task.status ?? 'pending',
                                            ),
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              color: _getStatusColor(
                                                task.status ?? 'pending',
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getPriorityColor(
                                              task.priority ?? 'low',
                                            ).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            (task.priority ?? 'low')
                                                .toUpperCase(),
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                              color: _getPriorityColor(
                                                task.priority ?? 'low',
                                              ),
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                SizedBox(height: 16),

                                // Task details
                                Row(
                                  children: [
                                    _buildDetailItem(
                                      Icons.schedule,
                                      'Due: ${task.dueDate != null ? _formatDate(task.dueDate!) : 'No due date'}',
                                      isOverdue
                                          ? Color(0xFFE74C3C)
                                          : Color(0xFFF39C12),
                                    ),
                                    SizedBox(width: 24),
                                    _buildDetailItem(
                                      Icons.person,
                                      'Assigned to: ${task.assignedTo ?? 'Unassigned'}',
                                      Color(0xFF5E8B7E),
                                    ),
                                    SizedBox(width: 24),
                                    if (task.taskGroup != null)
                                      _buildDetailItem(
                                        Icons.folder,
                                        'Group: ${task.taskGroup}',
                                        Color(0xFF30475E),
                                      ),
                                  ],
                                ),

                                if (task.notes != null &&
                                    task.notes!.isNotEmpty) ...[
                                  SizedBox(height: 16),
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF0F4F8),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.note,
                                          size: 16,
                                          color: Color(0xFF5E8B7E),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            task.notes!,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: Color(0xFF5E8B7E),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                if (task.tags != null &&
                                    task.tags!.isNotEmpty) ...[
                                  SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    children:
                                        task.tags!
                                            .map(
                                              (tag) => Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFFE3E8EF),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  tag,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    color: Color(0xFF5E8B7E),
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ],

                                SizedBox(height: 16),

                                // Actions
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (task.status != 'completed') ...[
                                      TextButton.icon(
                                        onPressed: () {
                                          // TODO: Mark task as in progress
                                        },
                                        icon: Icon(Icons.play_arrow, size: 18),
                                        label: Text('Start'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Color(0xFF5E8B7E),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          // TODO: Mark task as completed
                                        },
                                        icon: Icon(Icons.check, size: 18),
                                        label: Text('Complete'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF27AE60),
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF27AE60),
                                        size: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Completed',
                                        style: GoogleFonts.inter(
                                          color: Color(0xFF27AE60),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                    SizedBox(width: 16),
                                    TextButton.icon(
                                      onPressed: () {
                                        // TODO: Navigate to task detail
                                      },
                                      icon: Icon(Icons.visibility, size: 18),
                                      label: Text('View Details'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Color(0xFF5E8B7E),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFF0F4F8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Color(0xFF5E8B7E)),
            SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF30475E),
              ),
            ),
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 12, color: Color(0xFF5E8B7E)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedFilter = value;
        });
      },
      selectedColor: Color(0xFF5E8B7E),
      checkmarkColor: Colors.white,
      labelStyle: GoogleFonts.inter(
        color: isSelected ? Colors.white : Color(0xFF30475E),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 6),
        Text(text, style: GoogleFonts.inter(fontSize: 13, color: color)),
      ],
    );
  }
}
