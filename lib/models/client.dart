import 'package:hive/hive.dart';

part 'client.g.dart';

@HiveType(typeId: 0)
class Client extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String clientId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String email;

  @HiveField(4)
  final String phone;

  @HiveField(5)
  final String city;

  @HiveField(6)
  final String address;

  @HiveField(7)
  final DateTime? dob;

  @HiveField(8)
  final DateTime? weddingAnniversary;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  @HiveField(11)
  final String? firstName;

  @HiveField(12)
  final String? lastName;

  @HiveField(13)
  final String? gender;

  @HiveField(14)
  final String? age;

  @HiveField(15)
  final String? maritalStatus;

  @HiveField(16)
  final String? phoneNumber1;

  @HiveField(17)
  final String? phoneNumber2;

  @HiveField(18)
  final String? phoneNumber3;

  @HiveField(19)
  final String? state;

  @HiveField(20)
  final String? postCode;

  @HiveField(21)
  final String? country;

  @HiveField(22)
  final String? contactType1;

  @HiveField(23)
  final String? contactType2;

  @HiveField(24)
  final String? contactType3;

  @HiveField(25)
  final String? emailType;

  @HiveField(26)
  final String? email2;

  @HiveField(27)
  final bool? phoneVerify;

  @HiveField(28)
  final bool? emailVerify;

  @HiveField(29)
  final String? visaType;

  @HiveField(30)
  final String? visaExpiry;

  @HiveField(31)
  final String? preferredIntake;

  @HiveField(32)
  final String? passportCountry;

  @HiveField(33)
  final String? passportNumber;

  @HiveField(34)
  final String? nominatedOccupation;

  @HiveField(35)
  final String? skillAssessment;

  @HiveField(36)
  final String? highestQualificationAus;

  @HiveField(37)
  final String? highestQualificationOverseas;

  @HiveField(38)
  final String? workExpAus;

  @HiveField(39)
  final String? workExpOverseas;

  @HiveField(40)
  final String? englishScore;

  @HiveField(41)
  final String? themeMode;

  @HiveField(42)
  final bool isAdmin;

  Client({
    required this.id,
    required this.clientId,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.address,
    this.dob,
    this.weddingAnniversary,
    required this.createdAt,
    required this.updatedAt,
    this.firstName,
    this.lastName,
    this.gender,
    this.age,
    this.maritalStatus,
    this.phoneNumber1,
    this.phoneNumber2,
    this.phoneNumber3,
    this.state,
    this.postCode,
    this.country,
    this.contactType1,
    this.contactType2,
    this.contactType3,
    this.emailType,
    this.email2,
    this.phoneVerify,
    this.emailVerify,
    this.visaType,
    this.visaExpiry,
    this.preferredIntake,
    this.passportCountry,
    this.passportNumber,
    this.nominatedOccupation,
    this.skillAssessment,
    this.highestQualificationAus,
    this.highestQualificationOverseas,
    this.workExpAus,
    this.workExpOverseas,
    this.englishScore,
    this.themeMode,
    this.isAdmin = false,
  });

  // Factory constructor from JSON
  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? 0,
      clientId: json['client_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
      weddingAnniversary: json['wedding_anniversary'] != null 
          ? DateTime.parse(json['wedding_anniversary']) : null,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) : DateTime.now(),
      firstName: json['first_name'],
      lastName: json['last_name'],
      gender: json['gender'],
      age: json['age']?.toString(),
      maritalStatus: json['marital_status'],
      phoneNumber1: json['phone_number1'],
      phoneNumber2: json['phone_number2'],
      phoneNumber3: json['phone_number3'],
      state: json['state'],
      postCode: json['post_code'],
      country: json['country'],
      contactType1: json['contact_type1'],
      contactType2: json['contact_type2'],
      contactType3: json['contact_type3'],
      emailType: json['email_type'],
      email2: json['email2'],
      phoneVerify: json['phone_verify'] ?? false,
      emailVerify: json['email_verify'] ?? false,
      visaType: json['visa_type'],
      visaExpiry: json['visa_expiry'],
      preferredIntake: json['preferred_intake'],
      passportCountry: json['passport_country'],
      passportNumber: json['passport_number'],
      nominatedOccupation: json['nominated_occupation'],
      skillAssessment: json['skill_assessment'],
      highestQualificationAus: json['highest_qualification_aus'],
      highestQualificationOverseas: json['highest_qualification_overseas'],
      workExpAus: json['work_exp_aus'],
      workExpOverseas: json['work_exp_overseas'],
      englishScore: json['english_score'],
      themeMode: json['theme_mode'] ?? 'light',
      isAdmin: json['is_admin'] ?? false,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'name': name,
      'email': email,
      'phone': phone,
      'city': city,
      'address': address,
      'dob': dob?.toIso8601String(),
      'wedding_anniversary': weddingAnniversary?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender,
      'age': age,
      'marital_status': maritalStatus,
      'phone_number1': phoneNumber1,
      'phone_number2': phoneNumber2,
      'phone_number3': phoneNumber3,
      'state': state,
      'post_code': postCode,
      'country': country,
      'contact_type1': contactType1,
      'contact_type2': contactType2,
      'contact_type3': contactType3,
      'email_type': emailType,
      'email2': email2,
      'phone_verify': phoneVerify,
      'email_verify': emailVerify,
      'visa_type': visaType,
      'visa_expiry': visaExpiry,
      'preferred_intake': preferredIntake,
      'passport_country': passportCountry,
      'passport_number': passportNumber,
      'nominated_occupation': nominatedOccupation,
      'skill_assessment': skillAssessment,
      'highest_qualification_aus': highestQualificationAus,
      'highest_qualification_overseas': highestQualificationOverseas,
      'work_exp_aus': workExpAus,
      'work_exp_overseas': workExpOverseas,
      'english_score': englishScore,
      'theme_mode': themeMode,
      'is_admin': isAdmin,
    };
  }

  // Copy with method
  Client copyWith({
    int? id,
    String? clientId,
    String? name,
    String? email,
    String? phone,
    String? city,
    String? address,
    DateTime? dob,
    DateTime? weddingAnniversary,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? firstName,
    String? lastName,
    String? gender,
    String? age,
    String? maritalStatus,
    String? phoneNumber1,
    String? phoneNumber2,
    String? phoneNumber3,
    String? state,
    String? postCode,
    String? country,
    String? contactType1,
    String? contactType2,
    String? contactType3,
    String? emailType,
    String? email2,
    bool? phoneVerify,
    bool? emailVerify,
    String? visaType,
    String? visaExpiry,
    String? preferredIntake,
    String? passportCountry,
    String? passportNumber,
    String? nominatedOccupation,
    String? skillAssessment,
    String? highestQualificationAus,
    String? highestQualificationOverseas,
    String? workExpAus,
    String? workExpOverseas,
    String? englishScore,
    String? themeMode,
    bool? isAdmin,
  }) {
    return Client(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      address: address ?? this.address,
      dob: dob ?? this.dob,
      weddingAnniversary: weddingAnniversary ?? this.weddingAnniversary,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      phoneNumber1: phoneNumber1 ?? this.phoneNumber1,
      phoneNumber2: phoneNumber2 ?? this.phoneNumber2,
      phoneNumber3: phoneNumber3 ?? this.phoneNumber3,
      state: state ?? this.state,
      postCode: postCode ?? this.postCode,
      country: country ?? this.country,
      contactType1: contactType1 ?? this.contactType1,
      contactType2: contactType2 ?? this.contactType2,
      contactType3: contactType3 ?? this.contactType3,
      emailType: emailType ?? this.emailType,
      email2: email2 ?? this.email2,
      phoneVerify: phoneVerify ?? this.phoneVerify,
      emailVerify: emailVerify ?? this.emailVerify,
      visaType: visaType ?? this.visaType,
      visaExpiry: visaExpiry ?? this.visaExpiry,
      preferredIntake: preferredIntake ?? this.preferredIntake,
      passportCountry: passportCountry ?? this.passportCountry,
      passportNumber: passportNumber ?? this.passportNumber,
      nominatedOccupation: nominatedOccupation ?? this.nominatedOccupation,
      skillAssessment: skillAssessment ?? this.skillAssessment,
      highestQualificationAus: highestQualificationAus ?? this.highestQualificationAus,
      highestQualificationOverseas: highestQualificationOverseas ?? this.highestQualificationOverseas,
      workExpAus: workExpAus ?? this.workExpAus,
      workExpOverseas: workExpOverseas ?? this.workExpOverseas,
      englishScore: englishScore ?? this.englishScore,
      themeMode: themeMode ?? this.themeMode,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  // Get full name
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return name;
  }

  // Get display name
  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return name.isNotEmpty ? name : email;
  }

  // Check if profile is complete
  bool get isProfileComplete {
    return firstName != null && 
           lastName != null && 
           email.isNotEmpty && 
           phone.isNotEmpty &&
           address.isNotEmpty &&
           city.isNotEmpty;
  }

  // Get profile completion percentage
  double get profileCompletionPercentage {
    int completedFields = 0;
    int totalFields = 0;
    
    if (firstName != null && firstName!.isNotEmpty) completedFields++;
    totalFields++;
    
    if (lastName != null && lastName!.isNotEmpty) completedFields++;
    totalFields++;
    
    if (email.isNotEmpty) completedFields++;
    totalFields++;
    
    if (phone.isNotEmpty) completedFields++;
    totalFields++;
    
    if (address.isNotEmpty) completedFields++;
    totalFields++;
    
    if (city.isNotEmpty) completedFields++;
    totalFields++;
    
    if (state != null && state!.isNotEmpty) completedFields++;
    totalFields++;
    
    if (postCode != null && postCode!.isNotEmpty) completedFields++;
    totalFields++;
    
    if (country != null && country!.isNotEmpty) completedFields++;
    totalFields++;
    
    if (dob != null) completedFields++;
    totalFields++;
    
    if (gender != null && gender!.isNotEmpty) completedFields++;
    totalFields++;
    
    return totalFields > 0 ? completedFields / totalFields : 0.0;
  }

  @override
  String toString() {
    return 'Client(id: $id, clientId: $clientId, name: $name, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Client && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
