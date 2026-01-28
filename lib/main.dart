import 'package:flutter/material.dart';
import 'screens/matches_screen.dart';
import 'core/constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Dynasty',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentCyan,
          brightness: Brightness.dark,
          surface: AppColors.surface,
        ),
        useMaterial3: true,
      ),
      home: const MatchesScreen(),
    );
  }
}
