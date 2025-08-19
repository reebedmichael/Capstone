// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kos_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KosItem _$KosItemFromJson(Map<String, dynamic> json) => KosItem(
  kosItemId: json['KOS_ITEM_ID'] as String,
  kosItemNaam: json['KOS_ITEM_NAAM'] as String,
  kosItemBeskrywing: json['KOS_ITEM_BESKRYWING'] as String?,
  kosItemKoste: (json['KOS_ITEM_KOSTE'] as num?)?.toDouble(),
  kosItemPrentjie: json['KOS_ITEM_PRENTJIE'] as String?,
  isAktief: json['IS_AKTIEF'] as bool?,
);

Map<String, dynamic> _$KosItemToJson(KosItem instance) => <String, dynamic>{
  'KOS_ITEM_ID': instance.kosItemId,
  'KOS_ITEM_NAAM': instance.kosItemNaam,
  'KOS_ITEM_BESKRYWING': instance.kosItemBeskrywing,
  'KOS_ITEM_KOSTE': instance.kosItemKoste,
  'KOS_ITEM_PRENTJIE': instance.kosItemPrentjie,
  'IS_AKTIEF': instance.isAktief,
};
