class KositemTemplate {
  final String id;
  final String naam;
  final List<String> bestanddele;
  final List<String> allergene;
  final double prys;
  final String beskrywing;
  final String? prent;
  final int likes;

  /// NEW: dynamic dieet categories from DB
  final List<String> dieetKategorie;

  KositemTemplate({
    required this.id,
    required this.naam,
    required this.bestanddele,
    required this.beskrywing,
    required this.allergene,
    required this.prys,
    required this.dieetKategorie,
    this.prent,
    this.likes = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'naam': naam,
    'bestanddele': bestanddele,
    'beskrywing': beskrywing,
    'allergene': allergene,
    'prys': prys,
    'prent': prent,
    'likes': likes,
    'dieetKategorie': dieetKategorie,
  };

  factory KositemTemplate.fromMap(Map<String, dynamic> map) {
    return KositemTemplate(
      id: map['id'],
      naam: map['naam'],
      beskrywing: map['beskrywing'],
      bestanddele: List<String>.from(map['bestanddele']),
      allergene: List<String>.from(map['allergene']),
      prys: (map['prys'] as num).toDouble(),
      prent: map['prent'] as String?,
      likes: map['likes'] as int? ?? 0,
      dieetKategorie: (map['kos_item_dieet_vereistes'] as List<dynamic>? ?? [])
          .map((d) => d['dieet']?['dieet_naam'] as String)
          .toList(),
    );
  }
}
