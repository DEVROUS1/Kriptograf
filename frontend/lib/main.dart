import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: KriptoGrafApp()));
}

class KriptoGrafApp extends ConsumerWidget {
  const KriptoGrafApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'KriptoGraf Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: goRouter,
    );
  }
}
