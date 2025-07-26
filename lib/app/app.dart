import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/routes/app_router.dart';
import '../core/theme/app_theme.dart';
// ✅ IMPORTED

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    return MaterialApp.router(
      title: 'DSA Learning App',
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
