import 'dart:typed_data';

class KositemTemplate {
  final String id;
  final String naam;
  final List<String> bestanddele;
  final List<String> allergene;
  final double prys;
  final String kategorie;
  final String beskrywing;
  final String? prent;

  KositemTemplate({
    required this.id,
    required this.naam,
    required this.bestanddele,
    required this.beskrywing,
    required this.allergene,
    required this.prys,
    required this.kategorie,
    this.prent,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'naam': naam,
    'bestanddele': bestanddele,
    'beskrywing': beskrywing,
    'allergene': allergene,
    'prys': prys,
    'kategorie': kategorie,
    'prent': prent,
  };

  factory KositemTemplate.fromMap(Map<String, dynamic> map) {
    return KositemTemplate(
      id: map['id'],
      naam: map['naam'],
      beskrywing: map['beskrywing'],
      bestanddele: List<String>.from(map['bestanddele']),
      allergene: List<String>.from(map['allergene']),
      prys: (map['prys'] as num).toDouble(),
      kategorie: map['kategorie'],
      prent: map['prent'] as String?,
    );
  }
}
