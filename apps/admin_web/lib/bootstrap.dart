import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

Future<void> bootstrapSupabase() async {
  try {
    // Load environment variables
    await dotenv.load(fileName: kReleaseMode ? '.env.prod' : '.env.dev');
    
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    
    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception('Missing Supabase environment variables');
    }
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } catch (e) {
    print('Error loading environment variables: $e');
    // Fallback to hardcoded values for development
    await Supabase.initialize(
      url: 'https://fdtjqpkrgstoobgkmvva.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZkdGpxcGtyZ3N0b29iZ2ttdnZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA5MzkzMTksImV4cCI6MjA2NjUxNTMxOX0.mBhXEydwMYWxwUhrLR2ugVRbYFi0g1hRi3S3hzZhv-g',
    );
  }
}
