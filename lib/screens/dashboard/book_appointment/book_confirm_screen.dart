import 'dart:convert';

import 'package:client/screens/dashboard/book_appointment/book_confirm_appointment_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_loader.dart';
import 'booking_widget.dart';

class BookConfirmScreen extends StatefulWidget {
  const BookConfirmScreen({super.key});

  @override
  State<BookConfirmScreen> createState() => _BookConfirmScreenState();
}

class _BookConfirmScreenState extends State<BookConfirmScreen> {
  bool isLoading = true;
  bool isSubmitting = false;
  String? error;

  Map<String, dynamic> selectedOptions = {};

  Set<DateTime> disabledDates = {};
  List<int> disabledWeekdays = [];

  DateTime? selectedDay;
  String? selectedTime;

  final TextEditingController enquiryController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  int slotDuration = 15;
  String startTime = "10:45";
  String endTime = "16:00";

  bool get isAdd => selectedOptions['is_add'] ?? true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadCachedData();
    _populateControllers();
    await _fetchClientProfile();
    await loadCalendarData();
  }

  Future<void> _fetchClientProfile() async {
    try {
      final result = await ApiService.getClientProfile();

      if (result['success'] == true) {
        final data = result['data'];

        setState(() {
          fullNameController.text =
              "${data['first_name'] ?? ''} ${data['last_name'] ?? ''}".trim();

          emailController.text = data['email'] ?? '';
          String rawPhone = (data['phone'] ?? '').toString();
          rawPhone = rawPhone
              .replaceAll('+61', '')
              .replaceAll(RegExp(r'^61'), '')
              .trim();
          phoneController.text = rawPhone;
        });
      }
    } catch (e) {
      debugPrint("Profile fetch error: $e");
    }
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedOptions = prefs.getString("selectedOptions");

    if (cachedOptions != null) {
      selectedOptions = Map<String, dynamic>.from(jsonDecode(cachedOptions));
    }
  }

  void _populateControllers() {
    enquiryController.text = selectedOptions['description'] ?? '';
    fullNameController.text = selectedOptions['full_name'] ?? '';
    emailController.text = selectedOptions['email'] ?? '';
    phoneController.text = selectedOptions['phone'] ?? '';

    if (!isAdd) {
      final appointDate = selectedOptions['appoint_date'];
      if (appointDate != null) {
        selectedDay = DateTime.tryParse(appointDate);
      }
      selectedTime = selectedOptions['appoint_time'];
    }
  }

  @override
  void dispose() {
    enquiryController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> loadCalendarData() async {
    try {
      final res = await ApiService.getDisabledDates(
        id: selectedOptions['service_id'].toString(),
        enquiryItem: selectedOptions['noe_id'].toString(),
        inPersonAddress: selectedOptions['inperson_address'].toString(),
      );

      final data = res['data'];
      final formatter = DateFormat('dd/MM/yyyy');

      setState(() {
        disabledDates =
            (data['disabledatesarray'] as List)
                .map((d) => formatter.parse(d))
                .toSet();
        disabledWeekdays = List<int>.from(data['weeks']);
        slotDuration = data['duration'] ?? 15;
        startTime = data['start_time'] ?? "10:45";
        endTime = data['end_time'] ?? "16:00";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _goToConfirmation() {
    if (fullNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all personal details')),
      );
      return;
    }

    if (selectedDay == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    final formatter = DateFormat('yyyy-MM-dd');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => BookConfirmAppointmentScreen(
              selectedOptions: {
                ...selectedOptions,
                'full_name': fullNameController.text.trim(),
                'email': emailController.text.trim(),
                'phone': phoneController.text.trim(),
                'appoint_date': formatter.format(selectedDay!),
                'appoint_time': selectedTime!,
                'description': enquiryController.text.trim(),
              },
            ),
      ),
    );
  }

  void _submitAppointment() async {
    if (!isAdd) {
      if (selectedDay == null || selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select date and time')),
        );
        return;
      }

      setState(() => isSubmitting = true);

      try {
        final dateFormatter = DateFormat('yyyy-MM-dd');
        final formattedDate = dateFormatter.format(selectedDay!);
        final formattedTime = convertTo24Hour(selectedTime!);

        final response = await ApiService.updateAppointment(
          appointmentId: selectedOptions['id'],
          appointmentDate: formattedDate,
          appointmentTime: formattedTime,
          meetingType: 3,
          preferredLanguage: 1,
        );

        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment updated successfully')),
          );
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard',
            (Route<dynamic> route) => false,
            arguments: AuthService.selectedMatterId!.toString(),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['message'] ?? 'Failed to update appointment',
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => isSubmitting = false);
      }
    } else {
      _goToConfirmation();
    }
  }

  String convertTo24Hour(String time12h) {
    try {
      final cleanTime = time12h.replaceAll(RegExp(r'\s+'), '').toUpperCase();
      final regex = RegExp(r'^(\d{1,2}):(\d{2})(AM|PM)$');
      final match = regex.firstMatch(cleanTime);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final int minute = int.parse(match.group(2)!);
        final String period = match.group(3)!;
        if (period == 'PM' && hour != 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;
        return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      }
      throw FormatException('Invalid time format: $time12h');
    } catch (e) {
      debugPrint('Failed to parse time "$time12h": $e');
      return '00:00';
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputEnabled = isAdd;

    return ScaffoldWrapper(
      activeStep: 4,
      title: 'Confirm Appointment',
      child: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Your Details & Appointment Time'),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  return isMobile
                      ? Column(
                        children: [
                          AppTextField(
                            label: 'Full Name',
                            controller: fullNameController,
                            enabled: inputEnabled,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            label: 'Email Address',
                            controller: emailController,
                            enabled: inputEnabled,
                          ),
                        ],
                      )
                      : Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: 'Full Name',
                              controller: fullNameController,
                              enabled: inputEnabled,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppTextField(
                              label: 'Email Address',
                              controller: emailController,
                              enabled: inputEnabled,
                            ),
                          ),
                        ],
                      );
                },
              ),
              const SizedBox(height: 20),
              PhoneField(controller: phoneController, enabled: inputEnabled),
              const SizedBox(height: 20),
              TextField(
                controller: enquiryController,
                maxLines: 4,
                enabled: inputEnabled,
                decoration: InputDecoration(
                  labelText: 'Details of Enquiry',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF1E3A8A),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const SectionTitle('Select Date & Time'),
              const SizedBox(height: 12),
              const TimezoneBanner(),
              const SizedBox(height: 20),
              if (isLoading)
                const Center(child: AppLoader())
              else if (error != null)
                Text(error!, style: const TextStyle(color: Colors.red))
              else
                CalendarSection(
                  disabledDates: disabledDates,
                  disabledWeekdays: disabledWeekdays,
                  selectedOptions: selectedOptions,
                  onTimeSelected: (time) => selectedTime = time,
                  selectedDayCallback: (day) => selectedDay = day,
                  preSelectedDay: selectedDay,
                  preSelectedTime: selectedTime,
                  slotDuration: slotDuration,
                  startTime: startTime,
                  endTime: endTime,
                ),
              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: PreviousButton(
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),

                  const SizedBox(width: 16),
                  Expanded(
                    child: NextButton(
                      label: isAdd ? 'Review & Confirm' : 'Update Appointment',
                      isLoading: isSubmitting,
                      onTap:
                          isLoading || isSubmitting ? null : _submitAppointment,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF1E3A8A),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const PhoneField({super.key, required this.controller, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Center(child: Text('🇦🇺 +61')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                enabled: enabled,
                decoration: InputDecoration(
                  hintText: '000 000 000',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF1E3A8A),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class TimezoneBanner extends StatelessWidget {
  const TimezoneBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF6D83F2), Color(0xFF7B4AA1)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6D83F2).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(
            'All times shown in Melbourne Time (AEST)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class CalendarSection extends StatefulWidget {
  final Set<DateTime> disabledDates;
  final List<int> disabledWeekdays;
  final Map<String, dynamic> selectedOptions;
  final Function(String)? onTimeSelected;
  final Function(DateTime)? selectedDayCallback;
  final DateTime? preSelectedDay;
  final String? preSelectedTime;

  final int slotDuration;
  final String startTime;
  final String endTime;

  const CalendarSection({
    super.key,
    required this.disabledDates,
    required this.disabledWeekdays,
    required this.selectedOptions,
    this.onTimeSelected,
    this.selectedDayCallback,
    this.preSelectedDay,
    this.preSelectedTime,
    required this.slotDuration,
    required this.startTime,
    required this.endTime,
  });

  @override
  State<CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends State<CalendarSection> {
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;
  bool loadingSlots = false;
  List<String> availableSlots = [];
  String? selectedSlot;
  List<String> disabledTimeSlots = [];

  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool isDisabled(DateTime day) {
    if (day.isBefore(DateTime.now())) return true;
    if (widget.disabledDates.any((d) => sameDay(d, day))) return true;

    final apiWeekday = day.weekday % 7;
    return widget.disabledWeekdays.contains(apiWeekday);
  }

  @override
  void initState() {
    super.initState();
    selectedDay = widget.preSelectedDay;
    selectedSlot = widget.preSelectedTime;
    if (selectedDay != null) fetchAvailableSlots(selectedDay!);
  }

  Future<void> fetchAvailableSlots(DateTime date) async {
    setState(() {
      loadingSlots = true;
      availableSlots.clear();
      disabledTimeSlots.clear();
    });

    final formattedDate = DateFormat('dd/MM/yyyy').format(date);

    try {
      final res = await ApiService.getDisabledSlots(
        serviceId: widget.selectedOptions['service_id'].toString(),
        enquiryItem: widget.selectedOptions['noe_id'].toString(),
        inPersonAddress: widget.selectedOptions['inperson_address'].toString(),
        selectedDate: formattedDate,
      );

      disabledTimeSlots = List<String>.from(
        res['data']['disabledtimeslotes'] ?? [],
      );

      availableSlots =
          generateTimeSlots(
            widget.startTime,
            widget.endTime,
            widget.slotDuration,
          ).where((slot) => !disabledTimeSlots.contains(slot)).toList();
    } catch (e) {
      debugPrint('Disabled slot API error: $e');
    } finally {
      setState(() => loadingSlots = false);
    }
  }

  List<String> generateTimeSlots(String start, String end, int duration) {
    final List<String> slots = [];

    final startParts = start.split(":");
    final endParts = end.split(":");

    DateTime current = DateTime(
      0,
      0,
      0,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );
    DateTime last = DateTime(
      0,
      0,
      0,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );

    while (!current.add(Duration(minutes: duration)).isAfter(last)) {
      slots.add(DateFormat('h:mm a').format(current));
      current = current.add(Duration(minutes: duration));
    }

    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cols = screenWidth > 900 ? 4 : screenWidth > 600 ? 3 : 2;

    return Column(
      children: [
        TableCalendar(
          availableGestures: AvailableGestures.none,
          firstDay: DateTime(2025),
          lastDay: DateTime(2027),
          focusedDay: focusedDay,
          selectedDayPredicate:
              (d) => selectedDay != null && sameDay(selectedDay!, d),
          enabledDayPredicate: (day) => !isDisabled(day),
          onDaySelected: (selected, focused) {
            if (isDisabled(selected)) return;
            setState(() {
              selectedDay = selected;
              focusedDay = focused;
            });
            widget.selectedDayCallback?.call(selected);
            fetchAvailableSlots(selected);
          },
        ),
        const SizedBox(height: 16),
        loadingSlots
            ? const AppLoader()
            : GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3,
          ),
          itemCount: availableSlots.length,
          itemBuilder: (context, index) {
            final slot = availableSlots[index];
            final isSelected = slot == selectedSlot;
            return GestureDetector(
              onTap: widget.onTimeSelected != null
                  ? () {
                setState(() => selectedSlot = slot);
                widget.onTimeSelected?.call(slot);
              }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? const Color(0xFF1E3A8A)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color:
                        isSelected
                            ? const Color(0xFF1E3A8A)
                            : Colors.grey.shade300,
                  ),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                          : null,
                ),
                child: Text(
                  slot,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isSelected ? Colors.white : const Color(0xFF1E3A8A),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
