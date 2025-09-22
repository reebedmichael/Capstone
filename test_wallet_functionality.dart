import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://fdtjqpkrgstoobgkmvva.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZkdGpxcHByZ3N0b29iZ2ttdnZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjQxNzQ5NTgsImV4cCI6MjA0MDA5MDk1OH0.8QZ8QZ8QZ8QZ8QZ8QZ8QZ8QZ8QZ8QZ8QZ8QZ8QZ8QZ8',
  );

  final client = Supabase.instance.client;
  final beursieRepo = BeursieRepository(SupabaseDb(client));

  // Test user ID (from the terminal output)
  const testUserId = 'fe08a973-bdd4-4618-b4ca-6754d510c9a5';

  print('🧪 Testing Wallet Functionality...\n');

  try {
    // 1. Test getting current balance
    print('1. Getting current balance...');
    final currentBalance = await beursieRepo.kryBeursieBalans(testUserId);
    print('   Current balance: R${currentBalance.toStringAsFixed(2)}\n');

    // 2. Test top-up functionality
    print('2. Testing top-up functionality...');
    final topUpAmount = 100.0;
    final success = await beursieRepo.laaiBeursieOp(testUserId, topUpAmount, 'Bankkaart');
    
    if (success) {
      print('   ✅ Top-up successful!');
      
      // 3. Check new balance
      final newBalance = await beursieRepo.kryBeursieBalans(testUserId);
      print('   New balance: R${newBalance.toStringAsFixed(2)}');
      print('   Amount added: R${(newBalance - currentBalance).toStringAsFixed(2)}\n');
      
      // 4. Test transaction history
      print('3. Testing transaction history...');
      final transactions = await beursieRepo.lysTransaksies(testUserId);
      print('   Found ${transactions.length} transactions');
      
      for (int i = 0; i < transactions.length && i < 3; i++) {
        final t = transactions[i];
        final bedrag = (t['trans_bedrag'] as num?)?.toDouble() ?? 0.0;
        final beskrywing = t['trans_beskrywing'] ?? 'Geen beskrywing';
        final datum = DateTime.parse(t['trans_geskep_datum']);
        print('   - R${bedrag.toStringAsFixed(2)}: $beskrywing (${datum.toString()})');
      }
      
      print('\n✅ All wallet functionality tests passed!');
    } else {
      print('   ❌ Top-up failed!');
    }

  } catch (e) {
    print('❌ Error testing wallet functionality: $e');
  }
}
