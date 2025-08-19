import 'package:json_annotation/json_annotation.dart';

part 'gebruiker.g.dart';

@JsonSerializable()
class Gebruiker {
  @JsonKey(name: 'GEBR_ID')
  final String gebrId;
  @JsonKey(name: 'GEBR_EPOS')
  final String? gebrEpos;
  @JsonKey(name: 'GEBR_NAAM')
  final String? gebrNaam;
  @JsonKey(name: 'GEBR_VAN')
  final String? gebrVan;
  @JsonKey(name: 'BEURSIE_BALANS')
  final double? beursieBalans;
  @JsonKey(name: 'IS_AKTIEF')
  final bool? isAktief;
  @JsonKey(name: 'GEBR_TIPE_ID')
  final String? gebrTipeId;
  @JsonKey(name: 'ADMIN_TIPE_ID')
  final String? adminTipeId;
  @JsonKey(name: 'KAMPUS_ID')
  final String? kampusId;

  Gebruiker({
    required this.gebrId,
    this.gebrEpos,
    this.gebrNaam,
    this.gebrVan,
    this.beursieBalans,
    this.isAktief,
    this.gebrTipeId,
    this.adminTipeId,
    this.kampusId,
  });

  factory Gebruiker.fromJson(Map<String, dynamic> json) => _$GebruikerFromJson(json);
  Map<String, dynamic> toJson() => _$GebruikerToJson(this);
} 