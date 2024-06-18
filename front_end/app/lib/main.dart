import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Home());
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
          backgroundColor: Colors.grey[850],
          title: const Text('NutriBoom'),
          centerTitle: true,
          titleTextStyle: const TextStyle(color: Colors.green, fontSize: 40)),
      body: Column(
        //mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Calories:",
              style: TextStyle(color: Colors.green, fontSize: 20)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
                onPressed: () {
                  print("Pressed");
                },
                icon: const Icon(
                  Icons.add_circle_outline,
                  size: 80,
                  color: Colors.green,
                )),
          ])
        ],
      ),
    );
  }
}
