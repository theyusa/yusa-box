import 'package:flutter/material.dart';
import 'package:yusa_box/ui/screens/home_screen.dart';

void main() {
  runApp(const YusaBoxApp());
}

class YusaBoxApp extends StatelessWidget {
  const YusaBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YusaBox VPN',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}
