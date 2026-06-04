import 'package:client/utils/app_loader.dart';
import 'package:flutter/material.dart';

import '../../../../services/api_service.dart';
import '../../../../utils/responsive_utils.dart';


class AppointmentDetailScreen extends StatefulWidget {
  final int appointmentId;

  const AppointmentDetailScreen({super.key, required this.appointmentId});

  @override
  State<AppointmentDetailScreen> createState() =>
      _AppointmentDetailScreenState();
}

class _AppointmentDetailScreenState extends State<AppointmentDetailScreen> {
  bool isLoading = true;
  String? error;
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    fetchDetail();
  }

  Future<void> fetchDetail() async {
    try {
      final response = await ApiService.getAppointmentById(
        widget.appointmentId,
      );
      setState(() {
        data = response['data'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Color get _statusColor {
    final s =
        (data?['status_display'] ?? data?['status'] ?? '')
            .toString()
            .toLowerCase();
    if (s.contains('confirm')) return const Color(0xFF059669);
    if (s.contains('pend')) return const Color(0xFFD97706);
    if (s.contains('cancel')) return const Color(0xFFDC2626);
    if (s.contains('complet')) return const Color(0xFF7C3AED);
    return const Color(0xFF2563EB);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF9B000), Color(0xFFE09500)],
            ),
          ),
        ),
        title: const Text(
          'Appointment Details',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          isLoading
              ? const Center(child: AppLoader())
              : error != null
              ? _ErrorView(message: error!)
              : SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: AppResponsive.maxContentWidth,
                    ),
                    child: _buildBody(),
                  ),
                ),
              ),
    );
  }

  Widget _buildBody() {
    final d = data!;
    final color = _statusColor;

    return SingleChildScrollView(
      padding: AppResponsive.pagePadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── hero header ───────────────────────────────────────────────────
          _HeroCard(data: d, statusColor: color),
          const SizedBox(height: 16),

          // ── client info ───────────────────────────────────────────────────
          _SectionCard(
            icon: Icons.person_outline_rounded,
            title: 'Client Information',
            accentColor: const Color(0xFF2563EB),
            rows: [
              _RowData(
                icon: Icons.badge_outlined,
                label: 'Full Name',
                value: d['full_name'],
              ),
              _RowData(
                icon: Icons.email_outlined,
                label: 'Email',
                value: d['email'],
              ),
              _RowData(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: d['phone'],
              ),
              _RowData(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: d['location'],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── appointment details ───────────────────────────────────────────
          _SectionCard(
            icon: Icons.event_note_outlined,
            title: 'Appointment Details',
            accentColor: const Color(0xFF7C3AED),
            rows: [
              _RowData(
                icon: Icons.videocam_outlined,
                label: 'Meeting Type',
                value: d['meeting_type_display'],
              ),
              _RowData(
                icon: Icons.language_outlined,
                label: 'Language',
                value: d['preferred_language'],
              ),
              _RowData(
                icon: Icons.help_outline_rounded,
                label: 'Enquiry Type',
                value: d['enquiry_type_display'],
              ),
              _RowData(
                icon: Icons.info_outline,
                label: 'Status',
                value: d['status_display'],
                valueColor: color,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── payment summary ───────────────────────────────────────────────
          _PaymentCard(data: d),
          const SizedBox(height: 16),

          // ── enquiry notes ─────────────────────────────────────────────────
          if ((d['enquiry_details'] ?? '').toString().isNotEmpty)
            _NotesCard(notes: d['enquiry_details'].toString()),

          // ── cancellation ──────────────────────────────────────────────────
          if (d['cancellation_reason'] != null) ...[
            const SizedBox(height: 16),
            _CancellationCard(reason: d['cancellation_reason'].toString()),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─── Hero Card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color statusColor;

  const _HeroCard({required this.data, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(data['appointment_date'] ?? '') ??
        DateTime.now();
    final service = _capitalize(data['specific_service'] ?? '');
    final statusLabel =
        (data['status_display'] ?? data['status'] ?? 'Unknown').toString();
    final meetingType = data['meeting_type_display']?.toString() ?? '';
    final isVideo = meetingType.toLowerCase().contains('video');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top gradient accent
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [statusColor, statusColor.withValues(alpha: 0.3)],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service name + status badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          service,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Date + time block
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Date block
                        Column(
                          children: [
                            Container(
                              width: 62,
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _dayName(date),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: statusColor,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  Text(
                                    date.day.toString(),
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.w900,
                                      color: statusColor,
                                      height: 1.0,
                                    ),
                                  ),
                                  Text(
                                    _monthName(date),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: statusColor,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 16),

                        // Info lines
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _HeroInfoLine(
                                icon: Icons.calendar_today_outlined,
                                text: _formatFullDate(date),
                                color: statusColor,
                              ),
                              const SizedBox(height: 10),
                              _HeroInfoLine(
                                icon: Icons.access_time_rounded,
                                text: _formatTimeRange(
                                  data['appointment_time'],
                                  data['duration_minutes'],
                                ),
                                color: statusColor,
                              ),
                              if (meetingType.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                _HeroInfoLine(
                                  icon: isVideo
                                      ? Icons.videocam_outlined
                                      : Icons.location_on_outlined,
                                  text: meetingType,
                                  color: statusColor,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String text) => text
      .replaceAll("-", " ")
      .split(" ")
      .map((e) => e.isEmpty ? e : "${e[0].toUpperCase()}${e.substring(1)}")
      .join(" ");

  String _dayName(DateTime d) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[d.weekday - 1];
  }

  String _monthName(DateTime d) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return months[d.month - 1];
  }

  String _formatFullDate(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatTimeRange(String time, int duration) {
    final parts = time.split(":");
    final start = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final endMinutes = start.hour * 60 + start.minute + duration;
    final end = TimeOfDay(
      hour: (endMinutes ~/ 60) % 24,
      minute: endMinutes % 60,
    );
    return "${start.formatDummy()} – ${end.formatDummy()} · ${duration}min";
  }
}

class _HeroInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _HeroInfoLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _RowData {
  final IconData icon;
  final String label;
  final String? value;
  final Color? valueColor;

  const _RowData({
    required this.icon,
    required this.label,
    this.value,
    this.valueColor,
  });
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentColor;
  final List<_RowData> rows;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.06),
                border: Border(
                  bottom: BorderSide(
                    color: accentColor.withValues(alpha: 0.12),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, size: 16, color: accentColor),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),

            // Rows
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Column(
                children: rows.asMap().entries.map((entry) {
                  final i = entry.key;
                  final row = entry.value;
                  return Column(
                    children: [
                      _DetailRow(row: row, accentColor: accentColor),
                      if (i < rows.length - 1)
                        const Divider(
                          height: 1,
                          color: Color(0xFFF1F5F9),
                          indent: 28,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final _RowData row;
  final Color accentColor;

  const _DetailRow({required this.row, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Icon(
            row.icon,
            size: 15,
            color: accentColor.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 10),
          Text(
            row.label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              row.value ?? '—',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: row.valueColor ?? const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Payment Card ─────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _PaymentCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final amount = data['amount'];
    final discount = data['discount_amount'];
    final finalAmount = data['final_amount'];
    final paymentStatus = (data['payment'] ?? '').toString();
    final isPaid = paymentStatus.toLowerCase().contains('paid') ||
        paymentStatus.toLowerCase().contains('complet');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withValues(alpha: 0.06),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF059669).withValues(alpha: 0.12),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.payments_outlined,
                      size: 16,
                      color: Color(0xFF059669),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Payment Summary',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isPaid
                          ? const Color(0xFF059669).withValues(alpha: 0.1)
                          : const Color(0xFFD97706).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isPaid
                            ? const Color(0xFF059669).withValues(alpha: 0.3)
                            : const Color(0xFFD97706).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      paymentStatus,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isPaid
                            ? const Color(0xFF059669)
                            : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _PaymentRow(
                    label: 'Service Amount',
                    value: '\$$amount',
                    labelColor: const Color(0xFF64748B),
                    valueColor: const Color(0xFF1E293B),
                  ),
                  const SizedBox(height: 10),
                  _PaymentRow(
                    label: 'Discount',
                    value: '- \$$discount',
                    labelColor: const Color(0xFF64748B),
                    valueColor: const Color(0xFF059669),
                  ),
                  const SizedBox(height: 14),
                  Container(height: 1, color: const Color(0xFFE2E8F0)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payable',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '\$$finalAmount',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  const _PaymentRow({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: labelColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ─── Notes Card ───────────────────────────────────────────────────────────────

class _NotesCard extends StatelessWidget {
  final String notes;

  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.06),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.notes_rounded,
                      size: 16,
                      color: Color(0xFF0EA5E9),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Enquiry Notes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0EA5E9),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      notes,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Cancellation Card ────────────────────────────────────────────────────────

class _CancellationCard extends StatelessWidget {
  final String reason;

  const _CancellationCard({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDC2626).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.06),
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.cancel_outlined,
                      size: 16,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Cancellation Reason',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                reason,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 34,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TimeOfDay extension ──────────────────────────────────────────────────────

extension TimeFormat on TimeOfDay {
  String formatDummy() {
    final h = hourOfPeriod == 0 ? 12 : hourOfPeriod;
    final m = minute.toString().padLeft(2, '0');
    final p = period == DayPeriod.am ? "AM" : "PM";
    return "$h:$m $p";
  }
}
