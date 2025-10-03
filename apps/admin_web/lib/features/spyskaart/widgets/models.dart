// models.dart
import '../../templates/widgets/kos_item_templaat.dart';

class AppUser {
  final String id;
  final String naam;
  AppUser({required this.id, required this.naam});
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

class SpyskaartItem {
  final String itemId;
  final int quantity;
  final DateTime? cutoffTime;

  SpyskaartItem({
    required this.itemId,
    required this.quantity,
    this.cutoffTime,
  });
}

class WeekSpyskaart {
  final String id;
  final String status;
  final Map<String, List<String>> dae;
  final Map<String, Map<String, SpyskaartItem>>
  itemDetails; // day -> itemId -> SpyskaartItem
  final DateTime weekBegin;
  final DateTime weekEinde;
  final DateTime sperdatum;
  final String? goedgekeurDeur;
  final DateTime? goedgekeurDatum;

  WeekSpyskaart({
    required this.id,
    required this.status,
    required this.dae,
    required this.itemDetails,
    required this.weekBegin,
    required this.weekEinde,
    required this.sperdatum,
    this.goedgekeurDeur,
    this.goedgekeurDatum,
  });

  WeekSpyskaart copyWith({
    String? status,
    Map<String, List<String>>? dae,
    Map<String, Map<String, SpyskaartItem>>? itemDetails,
    String? goedgekeurDeur,
    DateTime? goedgekeurDatum,
  }) {
    return WeekSpyskaart(
      id: id,
      status: status ?? this.status,
      dae: dae ?? this.dae,
      itemDetails: itemDetails ?? this.itemDetails,
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
  final List<KositemTemplate> kositems;
  final List<KositemTemplate> kositemTemplates;
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
    List<KositemTemplate>? kositems,
    List<KositemTemplate>? kositemTemplates,
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
