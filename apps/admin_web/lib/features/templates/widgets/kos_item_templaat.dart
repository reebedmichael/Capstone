import 'dart:typed_data';

class KositemTemplate {
  final String id;
  final String naam;
  final List<String> bestanddele;
  final List<String> allergene;
  final double prys;
  final String kategorie;
  final Uint8List? prent;

  KositemTemplate({
    required this.id,
    required this.naam,
    required this.bestanddele,
    required this.allergene,
    required this.prys,
    required this.kategorie,
    this.prent,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'naam': naam,
    'bestanddele': bestanddele,
    'allergene': allergene,
    'prys': prys,
    'kategorie': kategorie,
    'prent': prent,
  };

  factory KositemTemplate.fromMap(Map<String, dynamic> map) {
    return KositemTemplate(
      id: map['id'],
      naam: map['naam'],
      bestanddele: List<String>.from(map['bestanddele']),
      allergene: List<String>.from(map['allergene']),
      prys: (map['prys'] as num).toDouble(),
      kategorie: map['kategorie'],
      prent: map['prent'],
    );
  }
}
