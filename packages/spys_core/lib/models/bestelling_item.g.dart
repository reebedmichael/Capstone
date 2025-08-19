// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bestelling_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BestellingItem _$BestellingItemFromJson(Map<String, dynamic> json) =>
    BestellingItem(
      bestKosId: json['BEST_KOS_ID'] as String,
      bestId: json['BEST_ID'] as String,
      kosItemId: json['KOS_ITEM_ID'] as String,
    );

Map<String, dynamic> _$BestellingItemToJson(BestellingItem instance) =>
    <String, dynamic>{
      'BEST_KOS_ID': instance.bestKosId,
      'BEST_ID': instance.bestId,
      'KOS_ITEM_ID': instance.kosItemId,
    };
