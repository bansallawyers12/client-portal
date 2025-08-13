import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../models/service.dart';
import '../../services/api_service.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;

  List<Appointment> _appointments = [];
  List<Service> _services = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAppointments();
    _loadServices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(seconds: 1));

      _loadMockAppointments();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load appointments: ${e.toString()}';
      });
    }
  }

  Future<void> _loadServices() async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      _loadMockServices();
    } catch (e) {
      // Handle error silently for now
      print('Failed to load services: $e');
    }
  }

  void _loadMockAppointments() {
    _appointments = [
      Appointment(
        id: 1,
        title: 'Visa Consultation',
        description: 'Initial consultation for student visa application',
        date: DateTime.now().add(const Duration(days: 3)),
        time: '10:00',
        status: 'confirmed',
        serviceId: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      Appointment(
        id: 2,
        title: 'Document Review',
        description: 'Review of submitted documents for work permit',
        date: DateTime.now().add(const Duration(days: 7)),
        time: '14:30',
        status: 'pending',
        serviceId: 2,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Appointment(
        id: 3,
        title: 'Interview Preparation',
        description: 'Preparation session for upcoming visa interview',
        date: DateTime.now().add(const Duration(days: 10)),
        time: '11:00',
        status: 'confirmed',
        serviceId: 3,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  void _loadMockServices() {
    _services = [
      Service(
        id: 1,
        title: 'Visa Consultation',
        description: 'Initial consultation for visa applications',
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Service(
        id: 2,
        title: 'Document Review',
        description: 'Review and verification of submitted documents',
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Service(
        id: 3,
        title: 'Interview Preparation',
        description: 'Preparation sessions for visa interviews',
        status: 'active',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 30)),
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
        appBar: AppBar(title: const Text('Appointments')),
        body: CustomErrorWidget(
          message: _errorMessage!,
          onRetry: _loadAppointments,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: Theme.of(context).cardColor,
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
                Tab(text: 'Cancelled'),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingTab(),
                _buildPastTab(),
                _buildCancelledTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBookingDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUpcomingTab() {
    final upcomingAppointments =
        _appointments
            .where(
              (appointment) =>
                  appointment.status == 'confirmed' ||
                  appointment.status == 'pending',
            )
            .where(
              (appointment) =>
                  appointment.date != null &&
                  appointment.date!.isAfter(DateTime.now()),
            )
            .toList()
          ..sort((a, b) => a.date!.compareTo(b.date!));

    return _buildAppointmentsList(upcomingAppointments, 'upcoming');
  }

  Widget _buildPastTab() {
    final pastAppointments =
        _appointments
            .where(
              (appointment) =>
                  appointment.status == 'completed' ||
                  appointment.status == 'cancelled',
            )
            .where(
              (appointment) =>
                  appointment.date != null &&
                  appointment.date!.isBefore(DateTime.now()),
            )
            .toList()
          ..sort((a, b) => b.date!.compareTo(a.date!));

    return _buildAppointmentsList(pastAppointments, 'past');
  }

  Widget _buildCancelledTab() {
    final cancelledAppointments =
        _appointments
            .where((appointment) => appointment.status == 'cancelled')
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return _buildAppointmentsList(cancelledAppointments, 'cancelled');
  }

  Widget _buildAppointmentsList(List<Appointment> appointments, String type) {
    if (appointments.isEmpty) {
      return _buildEmptyState(type);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final isUpcoming =
        appointment.date != null &&
        appointment.date!.isAfter(DateTime.now()) &&
        (appointment.status == 'confirmed' || appointment.status == 'pending');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAppointmentDetails(appointment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Status indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getStatusColor(appointment.status),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Appointment info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.title ?? 'Untitled Appointment',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),

                        if (appointment.description != null &&
                            appointment.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              appointment.description!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey.shade600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        appointment.status,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusLabel(appointment.status),
                      style: TextStyle(
                        color: _getStatusColor(appointment.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Date and time
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    appointment.date != null
                        ? DateFormat('MMM dd, yyyy').format(appointment.date!)
                        : 'No date set',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  if (appointment.time != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      appointment.time!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),

              // Actions for upcoming appointments
              if (isUpcoming)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rescheduleAppointment(appointment),
                          icon: const Icon(Icons.schedule),
                          label: const Text('Reschedule'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _cancelAppointment(appointment),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
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

  Widget _buildEmptyState(String type) {
    String title;
    String description;
    IconData icon;

    switch (type) {
      case 'upcoming':
        title = 'No upcoming appointments';
        description =
            'You don\'t have any upcoming appointments. Book one to get started!';
        icon = Icons.calendar_today;
        break;
      case 'past':
        title = 'No past appointments';
        description = 'You haven\'t had any appointments yet.';
        icon = Icons.history;
        break;
      case 'cancelled':
        title = 'No cancelled appointments';
        description = 'Great! You haven\'t cancelled any appointments.';
        icon = Icons.cancel;
        break;
      default:
        title = 'No appointments';
        description = 'No appointments found.';
        icon = Icons.calendar_today;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
          if (type == 'upcoming') ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showBookingDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Book Appointment'),
            ),
          ],
        ],
      ),
    );
  }

  void _showAppointmentDetails(Appointment appointment) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(appointment.title ?? 'Appointment Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (appointment.description != null &&
                    appointment.description!.isNotEmpty) ...[
                  Text(
                    'Description:',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(appointment.description!),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Date: ${appointment.date != null ? DateFormat('MMM dd, yyyy').format(appointment.date!) : 'Not set'}',
                ),
                if (appointment.time != null) Text('Time: ${appointment.time}'),
                Text('Status: ${_getStatusLabel(appointment.status)}'),
                if (appointment.serviceId != null) ...[
                  const SizedBox(height: 8),
                  Text('Service: ${_getServiceName(appointment.serviceId!)}'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showBookingDialog() {
    // TODO: Implement booking dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking functionality coming soon!')),
    );
  }

  void _rescheduleAppointment(Appointment appointment) {
    // TODO: Implement reschedule functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reschedule functionality coming soon!')),
    );
  }

  void _cancelAppointment(Appointment appointment) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cancel Appointment'),
            content: Text(
              'Are you sure you want to cancel "${appointment.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _performCancellation(appointment);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Yes, Cancel'),
              ),
            ],
          ),
    );
  }

  Future<void> _performCancellation(Appointment appointment) async {
    try {
      // TODO: Replace with actual API call
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        final index = _appointments.indexWhere((a) => a.id == appointment.id);
        if (index != -1) {
          _appointments[index] = appointment.copyWith(
            status: 'cancelled',
            updatedAt: DateTime.now(),
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment cancelled successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel appointment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return 'CONFIRMED';
      case 'pending':
        return 'PENDING';
      case 'cancelled':
        return 'CANCELLED';
      case 'completed':
        return 'COMPLETED';
      default:
        return 'UNKNOWN';
    }
  }

  String _getServiceName(int serviceId) {
    final service = _services.firstWhere(
      (s) => s.id == serviceId,
      orElse:
          () => Service(
            id: 0,
            title: 'Unknown Service',
            description: 'Unknown service',
            status: 'inactive',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
    );
    return service.title;
  }
}
