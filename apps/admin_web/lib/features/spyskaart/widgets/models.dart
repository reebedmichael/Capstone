// models.dart
import 'dart:typed_data';

class AppUser {
  final String id;
  final String naam;
  AppUser({required this.id, required this.naam});
}

class Kositem {
  final String id;
  final String naam;
  final List<String> bestanddele;
  final List<String> allergene;
  final double prys;
  final String kategorie;
  final Uint8List? prentBytes;
  final String? prentUrl;
  final bool beskikbaar;
  final String beskrywing;
  final DateTime geskep;

  Kositem({
    required this.id,
    required this.naam,
    required this.bestanddele,
    required this.allergene,
    required this.prys,
    required this.kategorie,
    this.prentBytes,
    this.prentUrl,
    this.beskikbaar = true,
    required this.beskrywing,
    DateTime? geskep,
  }) : geskep = geskep ?? DateTime.now();
}

class WeekTemplate {
  final String id;
  final String naam;
  final String? beskrywing;
  final Map<String, List<String>> dae;
  final DateTime geskep;

  WeekTemplate({
    required this.id,
    required this.naam,
    required this.dae,
    this.beskrywing,
    DateTime? geskep,
  }) : geskep = geskep ?? DateTime.now();
}

class WeekSpyskaart {
  final String id;
  final String status;
  final Map<String, List<String>> dae;
  final DateTime weekBegin;
  final DateTime weekEinde;
  final DateTime sperdatum;
  final String? goedgekeurDeur;
  final DateTime? goedgekeurDatum;

  WeekSpyskaart({
    required this.id,
    required this.status,
    required this.dae,
    required this.weekBegin,
    required this.weekEinde,
    required this.sperdatum,
    this.goedgekeurDeur,
    this.goedgekeurDatum,
  });

  WeekSpyskaart copyWith({
    String? status,
    Map<String, List<String>>? dae,
    String? goedgekeurDeur,
    DateTime? goedgekeurDatum,
  }) {
    return WeekSpyskaart(
      id: id,
      status: status ?? this.status,
      dae: dae ?? this.dae,
      weekBegin: weekBegin,
      weekEinde: weekEinde,
      sperdatum: sperdatum,
      goedgekeurDeur: goedgekeurDeur ?? this.goedgekeurDeur,
      goedgekeurDatum: goedgekeurDatum ?? this.goedgekeurDatum,
    );
  }
}

class AppState {
  final List<WeekSpyskaart> weekSpyskaarte;
  final List<Kositem> kositems;
  final List<Kositem> kositemTemplates;
  final List<WeekTemplate> weekTemplates;
  final AppUser? ingetekenGebruiker;

  AppState({
    required this.weekSpyskaarte,
    required this.kositems,
    required this.kositemTemplates,
    required this.weekTemplates,
    required this.ingetekenGebruiker,
  });

  AppState copyWith({
    List<WeekSpyskaart>? weekSpyskaarte,
    List<Kositem>? kositems,
    List<Kositem>? kositemTemplates,
    List<WeekTemplate>? weekTemplates,
    AppUser? ingetekenGebruiker,
  }) {
    return AppState(
      weekSpyskaarte: weekSpyskaarte ?? this.weekSpyskaarte,
      kositems: kositems ?? this.kositems,
      kositemTemplates: kositemTemplates ?? this.kositemTemplates,
      weekTemplates: weekTemplates ?? this.weekTemplates,
      ingetekenGebruiker: ingetekenGebruiker ?? this.ingetekenGebruiker,
    );
  }
}
