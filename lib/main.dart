import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'splash_screen.dart';
import 'HomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IIITNR Lab & Sports',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color.fromARGB(255, 0, 72, 126),
        useMaterial3: true,
        brightness: Brightness.light,
        cardTheme: CardThemeData(
          color: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 0, 72, 126)).surface.withOpacity(0.6),
            surfaceTintColor:
              const Color.fromARGB(0, 39, 149, 246), // Prevent Material 3 tint overlay
        ),
      ),
      home: const SplashScreen(),
      routes: {'/home': (context) => const HomePage()},
    );
  }
}

class BackgroundImageWrapper extends StatelessWidget {
  final Widget child;
  const BackgroundImageWrapper({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // Set background color to white
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/WhatsApp Image 2025-10-05 at 23.03.34_e30ecfe5.jpg',
              fit: BoxFit.fitWidth, // Don't enlarge vertically, fits by width
              opacity: const AlwaysStoppedAnimation(1),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
