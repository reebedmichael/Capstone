import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDb {
  SupabaseDb(this.client);
  final SupabaseClient client;

  PostgrestFilterBuilder<List<Map<String, dynamic>>> from(String table) => client.from(table).select();

  SupabaseClient get raw => client;
} 