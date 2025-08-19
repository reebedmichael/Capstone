import 'package:json_annotation/json_annotation.dart';

part 'kos_item.g.dart';

@JsonSerializable()
class KosItem {
  @JsonKey(name: 'KOS_ITEM_ID')
  final String kosItemId;
  @JsonKey(name: 'KOS_ITEM_NAAM')
  final String kosItemNaam;
  @JsonKey(name: 'KOS_ITEM_BESKRYWING')
  final String? kosItemBeskrywing;
  @JsonKey(name: 'KOS_ITEM_KOSTE')
  final double? kosItemKoste;
  @JsonKey(name: 'KOS_ITEM_PRENTJIE')
  final String? kosItemPrentjie;
  @JsonKey(name: 'IS_AKTIEF')
  final bool? isAktief;

  KosItem({
    required this.kosItemId,
    required this.kosItemNaam,
    this.kosItemBeskrywing,
    this.kosItemKoste,
    this.kosItemPrentjie,
    this.isAktief,
  });

  factory KosItem.fromJson(Map<String, dynamic> json) => _$KosItemFromJson(json);
  Map<String, dynamic> toJson() => _$KosItemToJson(this);
} 