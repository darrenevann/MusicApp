import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

// Notifier global untuk menyimpan status tema (Light/Dark)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Mendengarkan perubahan tema secara real-time
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Neo Music App',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          // Pengaturan Tema Terang
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFFFDFBF7), // Krem terang
            fontFamily: 'Roboto',
            brightness: Brightness.light,
          ),
          // Pengaturan Tema Gelap (Aesthetic Neo-Brutalism)
          darkTheme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFF121212), // Hitam pekat
            fontFamily: 'Roboto',
            brightness: Brightness.dark,
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}