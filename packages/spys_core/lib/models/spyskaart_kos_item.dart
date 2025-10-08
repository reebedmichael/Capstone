import 'package:json_annotation/json_annotation.dart';

part 'spyskaart_kos_item.g.dart';

@JsonSerializable()
class SpyskaartKosItem {
  @JsonKey(name: 'SPYSKAART_KOS_ID')
  final String spyskaartKosId;
  @JsonKey(name: 'SPYSKAART_KOS_AFSNY_DATUM')
  final String afsnyDatum;
  @JsonKey(name: 'SPYSKAART_ID')
  final String spyskaartId;
  @JsonKey(name: 'KOS_ITEM_ID')
  final String kosItemId;
  @JsonKey(name: 'WEEK_DAG_ID')
  final String weekDagId;

  SpyskaartKosItem({
    required this.spyskaartKosId,
    required this.afsnyDatum,
    required this.spyskaartId,
    required this.kosItemId,
    required this.weekDagId,
  });

  factory SpyskaartKosItem.fromJson(Map<String, dynamic> json) => _$SpyskaartKosItemFromJson(json);
  Map<String, dynamic> toJson() => _$SpyskaartKosItemToJson(this);
} 