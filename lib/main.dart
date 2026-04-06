import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/pharmacy_provider.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    debugPrint('Firebase init skipped due to error: $error');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = GoogleFonts.nunitoSansTextTheme();

    return ChangeNotifierProvider<PharmacyProvider>(
      create: (_) => PharmacyProvider()..loadPreferences(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'LazzPharma',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF3F8FF),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F5FC2),
            primary: const Color(0xFF0F5FC2),
            brightness: Brightness.light,
          ),
          textTheme: textTheme,
          appBarTheme: AppBarTheme(
            centerTitle: false,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF113259),
            elevation: 0,
            surfaceTintColor: Colors.white,
            titleTextStyle: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF113259),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F5FC2),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
