import 'package:flutter/material.dart';

import 'pantalla_notas.dart';

void main() => runApp(const NotasGestosApp());

class NotasGestosApp extends StatelessWidget {
  const NotasGestosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notas con gestos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5D4037)),
      ),
      home: const PantallaNotas(),
    );
  }
}
