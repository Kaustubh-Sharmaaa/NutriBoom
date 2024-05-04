import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 72, 82, 88),
          title: const Text('NutriBoom'),
          centerTitle: true,
          titleTextStyle: const TextStyle(color: Colors.green, fontSize: 40)),
    ));
  }
}
