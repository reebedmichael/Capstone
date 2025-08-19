import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DbTestPage extends StatefulWidget {
  const DbTestPage({super.key});

  @override
  State<DbTestPage> createState() => _DbTestPageState();
}

class _DbTestPageState extends State<DbTestPage> {
  List<dynamic> kosItems = const [];
  Map<String, dynamic>? gebruiker;
  bool loading = false;
  String? error;
  String debugInfo = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
      debugInfo = '';
    });
    
    try {
      final sb = Supabase.instance.client;
      
      // Debug: Check if we can connect
      debugInfo += 'Connecting to: ${dotenv.env['SUPABASE_URL']}\n';
      
      // Simple test first
      try {
        await sb.from('kos_item').select('count').limit(1);
        debugInfo += 'Count query: OK\n';
      } catch (e) {
        debugInfo += 'Count query failed: $e\n';
      }
      
      // Try the actual query
      final items = await sb.from('kos_item').select().limit(5);
      debugInfo += 'Main query: OK\n';
      
      Map<String, dynamic>? userRow;
      final uid = sb.auth.currentUser?.id;
      if (uid != null) {
        try {
          userRow = await sb.from('gebruikers').select().eq('gebr_id', uid).maybeSingle();
          debugInfo += 'User query: OK\n';
        } catch (e) {
          debugInfo += 'User query failed: $e\n';
        }
      } else {
        debugInfo += 'No user logged in\n';
      }
      
      setState(() {
        kosItems = items as List<dynamic>;
        gebruiker = userRow;
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DB Test')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fout: $error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      const Text('Debug Info:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(debugInfo, style: const TextStyle(fontFamily: 'monospace')),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('Debug Info:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(debugInfo, style: const TextStyle(fontFamily: 'monospace')),
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text('kos_item (eerste 5):', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...kosItems.map((e) => Text(e.toString())),
                    const SizedBox(height: 16),
                    const Divider(),
                    const Text('gebruiker (huidige):', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text((gebruiker ?? {}).toString()),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _load,
        child: const Icon(Icons.refresh),
      ),
    );
  }
} 