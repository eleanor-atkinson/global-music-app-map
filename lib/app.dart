import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env.dart';
import 'core/theme/app_theme.dart';
import 'features/map/presentation/screens/map_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: Env.appName,
      debugShowCheckedModeBanner: !Env.isProd,
      theme: AppTheme.dark,
      home: const MapScreen(),
    );
  }
}
