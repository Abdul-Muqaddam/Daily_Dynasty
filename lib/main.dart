import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/colors.dart';
import 'screens/splash_screen.dart';
import 'screens/customization_screen.dart';
import 'services/notification_service.dart';
import 'widgets/connectivity_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Disable the default Material 3 focus ring globally
  FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;

  // Initialize FCM push notifications in background so it doesn't block startup
  NotificationService.initialize();

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
        useMaterial3: true,
        // Disable global focus indicators
        focusColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accentCyan,
          brightness: Brightness.dark,
          surface: AppColors.surface,
        ).copyWith(
          outline: Colors.transparent,
          outlineVariant: Colors.transparent,
          primary: AppColors.accentCyan,
          // Explicitly set these to avoid "green" generation from seed if it happens
          secondary: AppColors.accentCyan.withOpacity(0.8),
          tertiary: AppColors.accentCyan.withOpacity(0.5),
        ),
        // Ensure inputs don't add their own borders on focus
        inputDecorationTheme: const InputDecorationTheme(
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
        // More aggressive focus neutralization
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.accentCyan,
          selectionColor: Colors.cyan,
          selectionHandleColor: AppColors.accentCyan,
        ),
      ),
      home: const ConnectivityWrapper(child: SplashScreen()),
      routes: {
        '/customization': (context) => const CustomizationScreen(),
      },
    );
  }
}
