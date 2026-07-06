import 'package:flutter/material.dart';
import 'screens/splashscreen.dart';
void main() {
  runApp(const NIA());
}

class NIA extends StatelessWidget {
  const NIA({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
    );
  }
}



