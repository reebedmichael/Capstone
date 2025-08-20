import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart';
import 'shared/services/auth_service.dart';

final sl = GetIt.instance;

void setupLocator() {
  final SupabaseClient sb = Supabase.instance.client;
  final db = SupabaseDb(sb);
  
  // Register repositories
  sl.registerLazySingleton<GebruikersRepository>(() => GebruikersRepository(db));
  sl.registerLazySingleton<BestellingRepository>(() => BestellingRepository(db));
  sl.registerLazySingleton<KampusRepository>(() => KampusRepository(db));
  sl.registerLazySingleton<SpyskaartRepository>(() => SpyskaartRepository(db));
  sl.registerLazySingleton<MandjieRepository>(() => MandjieRepository(db));
  sl.registerLazySingleton<BeursieRepository>(() => BeursieRepository(db));
  
  // Register auth service
  sl.registerLazySingleton<AuthService>(() => AuthService());
} 