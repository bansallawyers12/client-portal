// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClientAdapter extends TypeAdapter<Client> {
  @override
  final int typeId = 0;

  @override
  Client read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Client(
      id: fields[0] as int,
      clientId: fields[1] as String,
      name: fields[2] as String,
      email: fields[3] as String,
      phone: fields[4] as String,
      city: fields[5] as String,
      address: fields[6] as String,
      dob: fields[7] as DateTime?,
      weddingAnniversary: fields[8] as DateTime?,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
      firstName: fields[11] as String?,
      lastName: fields[12] as String?,
      gender: fields[13] as String?,
      age: fields[14] as String?,
      maritalStatus: fields[15] as String?,
      phoneNumber1: fields[16] as String?,
      phoneNumber2: fields[17] as String?,
      phoneNumber3: fields[18] as String?,
      state: fields[19] as String?,
      postCode: fields[20] as String?,
      country: fields[21] as String?,
      contactType1: fields[22] as String?,
      contactType2: fields[23] as String?,
      contactType3: fields[24] as String?,
      emailType: fields[25] as String?,
      email2: fields[26] as String?,
      phoneVerify: fields[27] as bool?,
      emailVerify: fields[28] as bool?,
      visaType: fields[29] as String?,
      visaExpiry: fields[30] as String?,
      preferredIntake: fields[31] as String?,
      passportCountry: fields[32] as String?,
      passportNumber: fields[33] as String?,
      nominatedOccupation: fields[34] as String?,
      skillAssessment: fields[35] as String?,
      highestQualificationAus: fields[36] as String?,
      highestQualificationOverseas: fields[37] as String?,
      workExpAus: fields[38] as String?,
      workExpOverseas: fields[39] as String?,
      englishScore: fields[40] as String?,
      themeMode: fields[41] as String?,
      isAdmin: fields[42] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Client obj) {
    writer
      ..writeByte(43)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.clientId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.phone)
      ..writeByte(5)
      ..write(obj.city)
      ..writeByte(6)
      ..write(obj.address)
      ..writeByte(7)
      ..write(obj.dob)
      ..writeByte(8)
      ..write(obj.weddingAnniversary)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.firstName)
      ..writeByte(12)
      ..write(obj.lastName)
      ..writeByte(13)
      ..write(obj.gender)
      ..writeByte(14)
      ..write(obj.age)
      ..writeByte(15)
      ..write(obj.maritalStatus)
      ..writeByte(16)
      ..write(obj.phoneNumber1)
      ..writeByte(17)
      ..write(obj.phoneNumber2)
      ..writeByte(18)
      ..write(obj.phoneNumber3)
      ..writeByte(19)
      ..write(obj.state)
      ..writeByte(20)
      ..write(obj.postCode)
      ..writeByte(21)
      ..write(obj.country)
      ..writeByte(22)
      ..write(obj.contactType1)
      ..writeByte(23)
      ..write(obj.contactType2)
      ..writeByte(24)
      ..write(obj.contactType3)
      ..writeByte(25)
      ..write(obj.emailType)
      ..writeByte(26)
      ..write(obj.email2)
      ..writeByte(27)
      ..write(obj.phoneVerify)
      ..writeByte(28)
      ..write(obj.emailVerify)
      ..writeByte(29)
      ..write(obj.visaType)
      ..writeByte(30)
      ..write(obj.visaExpiry)
      ..writeByte(31)
      ..write(obj.preferredIntake)
      ..writeByte(32)
      ..write(obj.passportCountry)
      ..writeByte(33)
      ..write(obj.passportNumber)
      ..writeByte(34)
      ..write(obj.nominatedOccupation)
      ..writeByte(35)
      ..write(obj.skillAssessment)
      ..writeByte(36)
      ..write(obj.highestQualificationAus)
      ..writeByte(37)
      ..write(obj.highestQualificationOverseas)
      ..writeByte(38)
      ..write(obj.workExpAus)
      ..writeByte(39)
      ..write(obj.workExpOverseas)
      ..writeByte(40)
      ..write(obj.englishScore)
      ..writeByte(41)
      ..write(obj.themeMode)
      ..writeByte(42)
      ..write(obj.isAdmin);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
