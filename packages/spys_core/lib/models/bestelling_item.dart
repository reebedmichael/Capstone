import 'package:json_annotation/json_annotation.dart';

part 'bestelling_item.g.dart';

@JsonSerializable()
class BestellingItem {
  @JsonKey(name: 'BEST_KOS_ID')
  final String bestKosId;
  @JsonKey(name: 'BEST_ID')
  final String bestId;
  @JsonKey(name: 'KOS_ITEM_ID')
  final String kosItemId;

  BestellingItem({
    required this.bestKosId,
    required this.bestId,
    required this.kosItemId,
  });

  factory BestellingItem.fromJson(Map<String, dynamic> json) => _$BestellingItemFromJson(json);
  Map<String, dynamic> toJson() => _$BestellingItemToJson(this);
} 