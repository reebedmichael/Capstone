// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gebruiker.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Gebruiker _$GebruikerFromJson(Map<String, dynamic> json) => Gebruiker(
  gebrId: json['GEBR_ID'] as String,
  gebrEpos: json['GEBR_EPOS'] as String?,
  gebrNaam: json['GEBR_NAAM'] as String?,
  gebrVan: json['GEBR_VAN'] as String?,
  beursieBalans: (json['BEURSIE_BALANS'] as num?)?.toDouble(),
  isAktief: json['IS_AKTIEF'] as bool?,
  gebrTipeId: json['GEBR_TIPE_ID'] as String?,
  adminTipeId: json['ADMIN_TIPE_ID'] as String?,
  kampusId: json['KAMPUS_ID'] as String?,
);

Map<String, dynamic> _$GebruikerToJson(Gebruiker instance) => <String, dynamic>{
  'GEBR_ID': instance.gebrId,
  'GEBR_EPOS': instance.gebrEpos,
  'GEBR_NAAM': instance.gebrNaam,
  'GEBR_VAN': instance.gebrVan,
  'BEURSIE_BALANS': instance.beursieBalans,
  'IS_AKTIEF': instance.isAktief,
  'GEBR_TIPE_ID': instance.gebrTipeId,
  'ADMIN_TIPE_ID': instance.adminTipeId,
  'KAMPUS_ID': instance.kampusId,
};
