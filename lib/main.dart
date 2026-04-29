import 'package:flutter/material.dart';
import 'core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HUOM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        backgroundColor: Color(0xFF1A1A2E),
        body: Center(
          child: Text(
            'HUOM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
