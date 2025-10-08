import 'package:json_annotation/json_annotation.dart';

part 'beursie_transaksie.g.dart';

@JsonSerializable()
class BeursieTransaksie {
  @JsonKey(name: 'TRANS_ID')
  final String transId;
  @JsonKey(name: 'TRANS_GESKEP_DATUM')
  final String transGeskeptDatum;
  @JsonKey(name: 'TRANS_BEDRAG')
  final double? transBedrag;
  @JsonKey(name: 'TRANS_BESKRYWING')
  final String? transBeskrywing;
  @JsonKey(name: 'GEBR_ID')
  final String gebrId;
  @JsonKey(name: 'TRANS_TIPE_ID')
  final String transTipeId;

  BeursieTransaksie({
    required this.transId,
    required this.transGeskeptDatum,
    required this.gebrId,
    required this.transTipeId,
    this.transBedrag,
    this.transBeskrywing,
  });

  factory BeursieTransaksie.fromJson(Map<String, dynamic> json) => _$BeursieTransaksieFromJson(json);
  Map<String, dynamic> toJson() => _$BeursieTransaksieToJson(this);
} 