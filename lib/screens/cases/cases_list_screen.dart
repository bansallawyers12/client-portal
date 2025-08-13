import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/case.dart';
import '../../services/api_service.dart';

class CasesListScreen extends StatefulWidget {
  const CasesListScreen({super.key});

  @override
  State<CasesListScreen> createState() => _CasesListScreenState();
}

class _CasesListScreenState extends State<CasesListScreen> {
  List<Case> cases = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchCases();
  }

  Future<void> _fetchCases() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // TODO: Replace with actual API call when backend is ready
      // final data = await ApiService.getCases();

      // Mock data for now
      await Future.delayed(Duration(milliseconds: 800));
      final mockCases = [
        Case(
          id: 1,
          name: 'Student Visa Application',
          status: 'in_progress',
          caseType: 'Student Visa',
          priority: 'high',
          createdAt: DateTime.now().subtract(Duration(days: 30)),
          updatedAt: DateTime.now().subtract(Duration(hours: 2)),
          estimatedCompletion: DateTime.now().add(Duration(days: 7)),
          description:
              'Processing student visa application for University of Melbourne',
        ),
        Case(
          id: 2,
          name: 'Partner Visa Sponsorship',
          status: 'pending_documents',
          caseType: 'Partner Visa',
          priority: 'medium',
          createdAt: DateTime.now().subtract(Duration(days: 45)),
          updatedAt: DateTime.now().subtract(Duration(days: 1)),
          estimatedCompletion: DateTime.now().add(Duration(days: 3)),
          description:
              'Partner visa sponsorship application awaiting required documents',
        ),
        Case(
          id: 3,
          name: 'Skilled Migration Assessment',
          status: 'completed',
          caseType: 'Skilled Migration',
          priority: 'low',
          createdAt: DateTime.now().subtract(Duration(days: 90)),
          updatedAt: DateTime.now().subtract(Duration(days: 5)),
          estimatedCompletion: null,
          description: 'Skills assessment completed successfully',
        ),
      ];

      setState(() {
        cases = mockCases;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF5E8B7E);
      case 'in_progress':
        return const Color(0xFFF39C12);
      case 'pending_documents':
        return const Color(0xFFE74C3C);
      case 'under_review':
        return const Color(0xFF3498DB);
      case 'approved':
        return const Color(0xFF27AE60);
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
      case 'pending_documents':
        return 'Pending Documents';
      case 'under_review':
        return 'Under Review';
      case 'approved':
        return 'Approved';
      default:
        return status;
    }
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
                  'My Cases',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to case creation screen
                  },
                  icon: Icon(Icons.add, size: 18),
                  label: Text('New Case'),
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

            // Case statistics
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
                    'Total Cases',
                    cases.length.toString(),
                    Icons.folder,
                  ),
                  SizedBox(width: 24),
                  _buildStatCard(
                    'Active Cases',
                    cases
                        .where((c) => c.status != 'completed')
                        .length
                        .toString(),
                    Icons.work,
                  ),
                  SizedBox(width: 24),
                  _buildStatCard(
                    'Pending Documents',
                    cases
                        .where((c) => c.status == 'pending_documents')
                        .length
                        .toString(),
                    Icons.pending,
                  ),
                  SizedBox(width: 24),
                  _buildStatCard(
                    'Completed',
                    cases
                        .where((c) => c.status == 'completed')
                        .length
                        .toString(),
                    Icons.check_circle,
                  ),
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
                      onPressed: _fetchCases,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (cases.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.folder_open, size: 64, color: Color(0xFFB0B7C3)),
                    SizedBox(height: 16),
                    Text(
                      'No cases found',
                      style: TextStyle(fontSize: 18, color: Color(0xFF5E8B7E)),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your cases will appear here once they are created',
                      style: TextStyle(fontSize: 14, color: Color(0xFFB0B7C3)),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: cases.length,
                  itemBuilder: (context, index) {
                    final caseItem = cases[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          // TODO: Navigate to case detail screen
                        },
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
                                          caseItem.name,
                                          style: GoogleFonts.spaceGrotesk(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF30475E),
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          caseItem.description ??
                                              'No description available',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Color(0xFF5E8B7E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(
                                            caseItem.status,
                                          ).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Text(
                                          _getStatusText(caseItem.status),
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            color: _getStatusColor(
                                              caseItem.status,
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
                                            caseItem.priority ?? 'low',
                                          ).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          (caseItem.priority ?? 'low')
                                              .toUpperCase(),
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                            color: _getPriorityColor(
                                              caseItem.priority ?? 'low',
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

                              // Progress bar
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Progress',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF30475E),
                                        ),
                                      ),
                                      Text(
                                        '${_calculateProgress(caseItem)}%',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF5E8B7E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: _calculateProgress(caseItem) / 100,
                                    backgroundColor: Color(0xFFE3E8EF),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF5E8B7E),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 16),

                              // Case details
                              Row(
                                children: [
                                  _buildDetailItem(
                                    Icons.person,
                                    'Agent: ${caseItem.agentId ?? 'Unassigned'}',
                                    Color(0xFF5E8B7E),
                                  ),
                                  SizedBox(width: 24),
                                  _buildDetailItem(
                                    Icons.category,
                                    caseItem.caseType ?? 'Unknown',
                                    Color(0xFF30475E),
                                  ),
                                  SizedBox(width: 24),
                                  if (caseItem.estimatedCompletion != null)
                                    _buildDetailItem(
                                      Icons.schedule,
                                      'Due: ${_formatDate(caseItem.estimatedCompletion!)}',
                                      Color(0xFFF39C12),
                                    ),
                                ],
                              ),

                              SizedBox(height: 16),

                              // Actions
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      // TODO: Navigate to case timeline
                                    },
                                    icon: Icon(Icons.timeline, size: 18),
                                    label: Text('Timeline'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Color(0xFF5E8B7E),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // TODO: Navigate to case detail
                                    },
                                    icon: Icon(Icons.visibility, size: 18),
                                    label: Text('View Details'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF5E8B7E),
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

  int _calculateProgress(Case caseItem) {
    // Calculate progress based on status
    switch (caseItem.status.toLowerCase()) {
      case 'completed':
        return 100;
      case 'in_progress':
        return 65;
      case 'pending_documents':
        return 25;
      case 'under_review':
        return 50;
      case 'approved':
        return 90;
      default:
        return 0;
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
}
