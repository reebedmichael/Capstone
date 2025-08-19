import 'package:json_annotation/json_annotation.dart';

part 'spyskaart.g.dart';

@JsonSerializable()
class Spyskaart {
  @JsonKey(name: 'SPYSKAART_ID')
  final String spyskaartId;
  @JsonKey(name: 'SPYSKAART_NAAM')
  final String spyskaartNaam;
  @JsonKey(name: 'SPYSKAART_IS_TEMPLAAT')
  final bool? spyskaartIsTemplaat;
  @JsonKey(name: 'SPYSKAART_DATUM')
  final String spyskaartDatum;

  Spyskaart({
    required this.spyskaartId,
    required this.spyskaartNaam,
    required this.spyskaartDatum,
    this.spyskaartIsTemplaat,
  });

  factory Spyskaart.fromJson(Map<String, dynamic> json) => _$SpyskaartFromJson(json);
  Map<String, dynamic> toJson() => _$SpyskaartToJson(this);
} 