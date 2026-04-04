import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Validate that required env vars were injected at build time.
  // If these asserts fire, you forgot --dart-define-from-file=env/<env>.json
  assert(Env.mapboxToken.isNotEmpty, 'MAPBOX_TOKEN is not set');
  assert(Env.supabaseUrl.isNotEmpty, 'SUPABASE_URL is not set');
  assert(Env.supabaseAnonKey.isNotEmpty, 'SUPABASE_ANON_KEY is not set');

  MapboxOptions.setAccessToken(Env.mapboxToken);

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    debug: Env.isDev,
  );

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
