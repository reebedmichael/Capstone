import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart';

// Email service provider
final emailServiceProvider = Provider<EmailService>((ref) {
  final supabaseClient = Supabase.instance.client;
  final db = SupabaseDb(supabaseClient);
  return EmailService(db);
});
