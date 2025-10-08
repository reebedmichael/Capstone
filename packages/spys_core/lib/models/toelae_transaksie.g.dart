// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'toelae_transaksie.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ToelaeTransaksie _$ToelaeTransaksieFromJson(Map<String, dynamic> json) =>
    ToelaeTransaksie(
      toelaeTransId: json['toelae_trans_id'] as String,
      gebrId: json['gebr_id'] as String,
      transBedrag: (json['trans_bedrag'] as num).toDouble(),
      transTipeId: json['trans_tipe_id'] as String,
      transBeskrywing: json['trans_beskrywing'] as String?,
      geskreDeur: json['geskep_deur'] as String?,
      transGeskepDatum: json['trans_geskep_datum'] as String,
    );

Map<String, dynamic> _$ToelaeTransaksieToJson(ToelaeTransaksie instance) =>
    <String, dynamic>{
      'toelae_trans_id': instance.toelaeTransId,
      'gebr_id': instance.gebrId,
      'trans_bedrag': instance.transBedrag,
      'trans_tipe_id': instance.transTipeId,
      'trans_beskrywing': instance.transBeskrywing,
      'geskep_deur': instance.geskreDeur,
      'trans_geskep_datum': instance.transGeskepDatum,
    };
