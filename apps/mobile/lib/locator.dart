import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart';

final sl = GetIt.instance;

void setupLocator() {
  final SupabaseClient sb = Supabase.instance.client;
  final db = SupabaseDb(sb);
  sl.registerLazySingleton<GebruikersRepository>(() => GebruikersRepository(db));
  sl.registerLazySingleton<BestellingRepository>(() => BestellingRepository(db));
  sl.registerLazySingleton<SpyskaartRepository>(() => SpyskaartRepository(db));
  sl.registerLazySingleton<MandjieRepository>(() => MandjieRepository(db));
  sl.registerLazySingleton<BeursieRepository>(() => BeursieRepository(db));
  sl.registerLazySingleton<ToelaeRepository>(() => ToelaeRepository(db));
  sl.registerLazySingleton<KampusRepository>(() => KampusRepository(db));
  sl.registerLazySingleton<DieetRepository>(() => DieetRepository(db));
  sl.registerLazySingleton<AllowanceRepository>(() => AllowanceRepository(db));
  sl.registerLazySingleton<TerugvoerRepository>(() => TerugvoerRepository(db));
} 