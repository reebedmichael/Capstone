// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spyskaart_kos_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpyskaartKosItem _$SpyskaartKosItemFromJson(Map<String, dynamic> json) =>
    SpyskaartKosItem(
      spyskaartKosId: json['SPYSKAART_KOS_ID'] as String,
      afsnyDatum: json['SPYSKAART_KOS_AFSNY_DATUM'] as String,
      spyskaartId: json['SPYSKAART_ID'] as String,
      kosItemId: json['KOS_ITEM_ID'] as String,
      weekDagId: json['WEEK_DAG_ID'] as String,
    );

Map<String, dynamic> _$SpyskaartKosItemToJson(SpyskaartKosItem instance) =>
    <String, dynamic>{
      'SPYSKAART_KOS_ID': instance.spyskaartKosId,
      'SPYSKAART_KOS_AFSNY_DATUM': instance.afsnyDatum,
      'SPYSKAART_ID': instance.spyskaartId,
      'KOS_ITEM_ID': instance.kosItemId,
      'WEEK_DAG_ID': instance.weekDagId,
    };
