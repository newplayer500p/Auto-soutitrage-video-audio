import 'package:flutter/material.dart';
import 'pages/accueil_page.dart';
import 'pages/upload_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MonAppState();
}

class _MonAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Sous-titrage Vidéo",

      theme: ThemeData.light(
        useMaterial3: true,
      ).copyWith(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),

      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),

      themeMode: _themeMode,

      routes: {
        '/': (context) => AccueilPage(onToggleTheme: _toggleTheme),
        '/upload': (context) => UploadPage(),
      },
    );
  }
}
