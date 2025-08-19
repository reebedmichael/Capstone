// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spyskaart.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Spyskaart _$SpyskaartFromJson(Map<String, dynamic> json) => Spyskaart(
  spyskaartId: json['SPYSKAART_ID'] as String,
  spyskaartNaam: json['SPYSKAART_NAAM'] as String,
  spyskaartDatum: json['SPYSKAART_DATUM'] as String,
  spyskaartIsTemplaat: json['SPYSKAART_IS_TEMPLAAT'] as bool?,
);

Map<String, dynamic> _$SpyskaartToJson(Spyskaart instance) => <String, dynamic>{
  'SPYSKAART_ID': instance.spyskaartId,
  'SPYSKAART_NAAM': instance.spyskaartNaam,
  'SPYSKAART_IS_TEMPLAAT': instance.spyskaartIsTemplaat,
  'SPYSKAART_DATUM': instance.spyskaartDatum,
};
