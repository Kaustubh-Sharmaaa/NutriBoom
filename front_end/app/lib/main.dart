//import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Home());
  }
}

class FoodData {
  FoodData(this.calorie, this.protein);
  final double calorie;
  final double protein;
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final List<FoodData> ChartData = [
      FoodData(250, 10),
      FoodData(500, 30),
      FoodData(150, 2),
      FoodData(330, 12),
      FoodData(420, 8)
    ];

    double consumedCalories = 0;
    double consumedProteins = 0;
    for (FoodData food in ChartData) {
      consumedCalories += food.calorie;
      consumedProteins += food.protein;
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
          backgroundColor: Colors.grey[850],
          title: const Text('NutriBoom'),
          centerTitle: true,
          titleTextStyle: const TextStyle(color: Colors.green, fontSize: 40)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Calories:",
                style: TextStyle(
                    color: Colors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            SfRadialGauge(
              axes: [
                RadialAxis(
                  maximum: 1900,
                  pointers: [
                    RangePointer(
                      color: Colors.green,
                      value: consumedCalories,
                    ),
                  ],
                )
              ],
            ),
            const Text("Protein:",
                style: TextStyle(
                    color: Colors.green,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            SfRadialGauge(
              axes: [
                RadialAxis(
                  maximum: 100,
                  pointers: [
                    RangePointer(
                      color: Colors.green,
                      value: consumedProteins,
                    ),
                  ],
                )
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: FloatingActionButton.extended(
          label: Text(
            "Add Food",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
          backgroundColor: Colors.grey[850],
          onPressed: () {
            print("Pressed");
          },
          icon: const Icon(
            Icons.add_circle_outline,
            size: 50,
            color: Colors.green,
          )),
    );
  }
}
