import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrapSupabase() async {
  // Use hardcoded values for now since .env files are not available
  await Supabase.initialize(
    url: 'https://fdtjqpkrgstoobgkmvva.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZkdGpxcGtyZ3N0b29iZ2ttdnZhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA5MzkzMTksImV4cCI6MjA2NjUxNTMxOX0.mBhXEydwMYWxwUhrLR2ugVRbYFi0g1hRi3S3hzZhv-g',
  );
}
