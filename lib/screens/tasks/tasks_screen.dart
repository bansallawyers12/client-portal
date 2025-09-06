import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String _statusFilter = 'all';
  String _priorityFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Mock tasks data - replace with actual API call
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
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
        Task(
          id: 3,
            title: 'Complete application form',
            dueDate: DateTime.now().add(const Duration(days: 2)),
          priority: 'high',
            status: 'pending',
            createdAt: DateTime.now().subtract(const Duration(days: 7)),
            updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        Task(
          id: 4,
            title: 'Review case documents',
            dueDate: DateTime.now().subtract(const Duration(days: 1)),
            priority: 'low',
            status: 'completed',
            createdAt: DateTime.now().subtract(const Duration(days: 10)),
            updatedAt: DateTime.now().subtract(const Duration(hours: 6)),
          ),
          Task(
            id: 5,
            title: 'Prepare for interview',
            dueDate: DateTime.now().add(const Duration(days: 7)),
          priority: 'medium',
            status: 'in_progress',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
            updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load tasks: ${e.toString()}';
      });
    }
  }

  List<Task> get _filteredTasks {
    return _tasks.where((task) {
      final matchesSearch = (task.title?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesStatus = _statusFilter == 'all' || task.status == _statusFilter;
      final matchesPriority = _priorityFilter == 'all' || task.priority == _priorityFilter;
      return matchesSearch && matchesStatus && matchesPriority;
    }).toList();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
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

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'high':
        return 'High';
      case 'medium':
        return 'Medium';
      case 'low':
        return 'Low';
      default:
        return priority;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.keyboard_arrow_down;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'in_progress':
        return Icons.timeline;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  bool _isOverdue(DateTime dueDate) {
    return dueDate.isBefore(DateTime.now()) && 
           !_tasks.any((task) => task.dueDate == dueDate && task.status == 'completed');
  }

  bool _isDueSoon(DateTime dueDate) {
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    return daysUntilDue <= 3 && daysUntilDue >= 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Tasks'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
        child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Status Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                      _buildFilterChip('All', 'all', 'status'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', 'pending', 'status'),
                      const SizedBox(width: 8),
                      _buildFilterChip('In Progress', 'in_progress', 'status'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Completed', 'completed', 'status'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                
                // Priority Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Priorities', 'all', 'priority'),
                      const SizedBox(width: 8),
                      _buildFilterChip('High', 'high', 'priority'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Medium', 'medium', 'priority'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Low', 'low', 'priority'),
                    ],
                  ),
                  ),
                ],
              ),
            ),

          // Tasks List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                    ElevatedButton(
                              onPressed: _loadTasks,
                              child: const Text('Retry'),
                    ),
                  ],
                ),
              )
                    : _filteredTasks.isEmpty
                        ? Center(
                child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                                Icon(
                                  Icons.task_alt,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                    Text(
                                  _searchQuery.isNotEmpty || _statusFilter != 'all' || _priorityFilter != 'all'
                                      ? 'No tasks match your search'
                                      : 'No tasks found',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                    ),
                  ],
                ),
              )
                        : RefreshIndicator(
                            onRefresh: _loadTasks,
                child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredTasks.length,
                  itemBuilder: (context, index) {
                                final task = _filteredTasks[index];
                                return _buildTaskCard(task);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String type) {
    final isSelected = type == 'status' 
        ? _statusFilter == value 
        : _priorityFilter == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (type == 'status') {
            _statusFilter = value;
          } else {
            _priorityFilter = value;
          }
        });
      },
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildTaskCard(Task task) {
    final isOverdue = task.dueDate != null ? _isOverdue(task.dueDate!) : false;
    final isDueSoon = task.dueDate != null ? _isDueSoon(task.dueDate!) : false;

                    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
                      child: InkWell(
                        onTap: () {
          _showTaskDetails(task);
        },
        borderRadius: BorderRadius.circular(12),
                          child: Padding(
          padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.task,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                                    Expanded(
                    child: Text(
                      task.title ?? 'Untitled Task',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: task.status == 'completed' 
                            ? TextDecoration.lineThrough 
                            : null,
                      ),
                    ),
                  ),
                  Row(
                                        children: [
                      // Priority Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(task.priority ?? 'unknown').withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getPriorityColor(task.priority ?? 'unknown').withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getPriorityIcon(task.priority ?? 'unknown'),
                              size: 12,
                              color: _getPriorityColor(task.priority ?? 'unknown'),
                            ),
                            const SizedBox(width: 2),
                                          Text(
                              _getPriorityText(task.priority ?? 'unknown'),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _getPriorityColor(task.priority ?? 'unknown'),
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                      const SizedBox(width: 8),
                      // Status Badge
                                        Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                          color: _getStatusColor(task.status ?? 'unknown').withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(task.status ?? 'unknown').withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(task.status ?? 'unknown'),
                              size: 14,
                              color: _getStatusColor(task.status ?? 'unknown'),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getStatusText(task.status ?? 'unknown'),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _getStatusColor(task.status ?? 'unknown'),
                                              fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
              const SizedBox(height: 12),

                                Row(
                                  children: [
                  Icon(
                                      Icons.schedule,
                    size: 16,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${task.dueDate != null ? DateFormat('MMM d, y').format(task.dueDate!) : 'No due date'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    ),
                                      ),
                                  ],
                                ),
              const SizedBox(height: 8),

              if (isOverdue)
                                  Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                    mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                        Icons.warning,
                        size: 14,
                        color: Colors.red[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Overdue',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                )
              else if (isDueSoon)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                                  children: [
                                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 4),
                                      Text(
                        'Due Soon',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                      ),
                                    ),
                                  ],
                                ),
        ),
      ),
    );
  }

  void _showTaskDetails(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
            Text(
                    task.title ?? 'Untitled Task',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: task.status == 'completed' 
                          ? TextDecoration.lineThrough 
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDetailRow(Icons.schedule, 'Due Date', 
                    task.dueDate != null ? DateFormat('EEEE, MMMM d, y').format(task.dueDate!) : 'No due date'),
                  _buildDetailRow(Icons.priority_high, 'Priority', _getPriorityText(task.priority ?? 'unknown')),
                  _buildDetailRow(Icons.info, 'Status', _getStatusText(task.status ?? 'unknown')),
                  _buildDetailRow(Icons.schedule, 'Created', 
                    DateFormat('MMM d, y').format(task.createdAt)),
                  
                  const SizedBox(height: 24),
                  
                  if (task.status != 'completed')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // TODO: Implement mark as complete functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Mark as complete functionality not implemented yet')),
                          );
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Mark as Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  
                  if (task.status == 'pending')
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // TODO: Implement start task functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Start task functionality not implemented yet')),
                          );
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Task'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                          side: BorderSide(color: Theme.of(context).primaryColor),
                        ),
                      ),
            ),
          ],
        ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
      children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}