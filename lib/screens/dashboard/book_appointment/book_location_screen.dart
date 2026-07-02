import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/appointment/appointment_variable_list.dart';
import '../../../services/api_service.dart';
import '../../../utils/app_loader.dart';
import '../../../utils/cache_helper.dart';
import 'appointment_list/appointment_list.dart';
import 'book_service_screen.dart';
import 'booking_widget.dart';

class BookLocationScreen extends StatefulWidget {
  const BookLocationScreen({super.key});

  @override
  State<BookLocationScreen> createState() => _BookLocationScreenState();
}

class _BookLocationScreenState extends State<BookLocationScreen> {
  bool isLoading = true;

  List<LocationModel> locations = [];
  List<MeetingTypeModel> meetingTypes = [];
  List<LanguageModel> languages = [];
  List<ServiceTypeModel> services = [];
  List<SimpleServiceModel> serviceCategories = [];

  LocationModel? selectedLocation;
  MeetingTypeModel? selectedMeeting;
  LanguageModel? selectedLanguage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();

    final cachedLocations = prefs.getString('locations');
    final cachedMeetingTypes = prefs.getString('meetingTypes');
    final cachedLanguages = prefs.getString('languages');
    final cachedServices = prefs.getString('services');
    final cachedServiceCategories = prefs.getString('serviceCategories');

    if (cachedLocations != null &&
        cachedMeetingTypes != null &&
        cachedLanguages != null &&
        cachedServices != null &&
        cachedServiceCategories != null) {
      // Load from cache
      locations =
          (jsonDecode(cachedLocations) as List)
              .map((e) => LocationModel.fromJson(e))
              .toList();
      meetingTypes =
          (jsonDecode(cachedMeetingTypes) as List)
              .map((e) => MeetingTypeModel.fromJson(e))
              .toList();
      languages =
          (jsonDecode(cachedLanguages) as List)
              .map((e) => LanguageModel.fromJson(e))
              .toList();
      services =
          (jsonDecode(cachedServices) as List)
              .map((e) => ServiceTypeModel.fromJson(e))
              .toList();
      serviceCategories =
          (jsonDecode(cachedServiceCategories) as List)
              .map((e) => SimpleServiceModel.fromJson(e))
              .toList();

      selectedLocation = locations.first;
      selectedMeeting = meetingTypes.first;
      selectedLanguage = languages.first;

      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await ApiService.getAppointmentVariableLists();
      final data = response['data'];

      locations =
          (data['location'] as List)
              .map((e) => LocationModel.fromJson(e))
              .toList();
      meetingTypes =
          (data['meeting_type'] as List)
              .map((e) => MeetingTypeModel.fromJson(e))
              .toList();
      languages =
          (data['preferred_language'] as List)
              .map((e) => LanguageModel.fromJson(e))
              .toList();
      services =
          (data['service_type'] as List)
              .map((e) => ServiceTypeModel.fromJson(e))
              .toList();
      serviceCategories =
          (data['select_your_service'] as List)
              .map((e) => SimpleServiceModel.fromJson(e))
              .toList();

      selectedLocation = locations.first;
      selectedMeeting = meetingTypes.first;
      selectedLanguage = languages.first;

      await CacheHelper.saveData(key: 'locations', data: locations);
      await CacheHelper.saveData(key: 'meetingTypes', data: meetingTypes);
      await CacheHelper.saveData(key: 'languages', data: languages);
      await CacheHelper.saveData(key: 'services', data: services);
      await CacheHelper.saveData(
        key: 'serviceCategories',
        data: serviceCategories,
      );

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint("API Error: $e");
      setState(() => isLoading = false);
    }
  }

  IconData _iconFromString(String icon) {
    switch (icon) {
      case 'phone':
        return Icons.phone;
      case 'building':
        return Icons.apartment;
      case 'video':
        return Icons.videocam;
      default:
        return Icons.help;
    }
  }

  Widget _cardWidth(BuildContext context, Widget child) {
    final width = MediaQuery.of(context).size.width;
    return SizedBox(
      width:
          width > 900
              ? 320
              : width > 600
              ? 280
              : width - 100,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWrapper(
      title: 'Choose Your Preferred Location',
      activeStep: 1,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AppointmentListScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.history_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: const Text(
                'My Booking\nHistory',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
      child:
          isLoading
              ? SizedBox(
                height: MediaQuery.of(context).size.height / 2,
                child: const Center(child: AppLoader()),
              )
              : SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('Select Office Location'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children:
                          locations
                              .map(
                                (location) => _cardWidth(
                                  context,
                                  SelectionCard(
                                    title: location.name,
                                    subtitle: location.fullAddress,
                                    isSelected:
                                        selectedLocation?.id == location.id,
                                    onTap:
                                        () => setState(
                                          () => selectedLocation = location,
                                        ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 32),
                    const SectionTitle('Meeting Type'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children:
                          meetingTypes
                              .map(
                                (meeting) => _cardWidth(
                                  context,
                                  SelectionCard(
                                    icon: _iconFromString(meeting.icon),
                                    title: meeting.name,
                                    subtitle: meeting.description,
                                    isSelected:
                                        selectedMeeting?.id == meeting.id,
                                    onTap:
                                        () => setState(
                                          () => selectedMeeting = meeting,
                                        ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 32),
                    const SectionTitle('Preferred Language'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children:
                          languages
                              .map(
                                (lang) => _cardWidth(
                                  context,
                                  SelectionCard(
                                    title: "${lang.flag} ${lang.name}",
                                    isSelected: selectedLanguage?.id == lang.id,
                                    onTap:
                                        () => setState(
                                          () => selectedLanguage = lang,
                                        ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                    const SizedBox(height: 40),
                    NextButton(
                      onTap: () async {
                        Map<String, dynamic> selectedOptions = {
                          'location_name': selectedLocation?.name.toString(),
                          'meeting_type': selectedMeeting?.name.toString(),
                          'inperson_address': selectedLocation?.id.toString(),
                          'appointment_details': selectedMeeting?.id.toString(),
                          'preferred_language': selectedLanguage?.id.toString(),
                        };
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString(
                          'selectedOptions',
                          jsonEncode(selectedOptions),
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookServiceScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
    );
  }
}
