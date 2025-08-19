// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'beursie_transaksie.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BeursieTransaksie _$BeursieTransaksieFromJson(Map<String, dynamic> json) =>
    BeursieTransaksie(
      transId: json['TRANS_ID'] as String,
      transGeskeptDatum: json['TRANS_GESKEP_DATUM'] as String,
      gebrId: json['GEBR_ID'] as String,
      transTipeId: json['TRANS_TIPE_ID'] as String,
      transBedrag: (json['TRANS_BEDRAG'] as num?)?.toDouble(),
      transBeskrywing: json['TRANS_BESKRYWING'] as String?,
    );

Map<String, dynamic> _$BeursieTransaksieToJson(BeursieTransaksie instance) =>
    <String, dynamic>{
      'TRANS_ID': instance.transId,
      'TRANS_GESKEP_DATUM': instance.transGeskeptDatum,
      'TRANS_BEDRAG': instance.transBedrag,
      'TRANS_BESKRYWING': instance.transBeskrywing,
      'GEBR_ID': instance.gebrId,
      'TRANS_TIPE_ID': instance.transTipeId,
    };
