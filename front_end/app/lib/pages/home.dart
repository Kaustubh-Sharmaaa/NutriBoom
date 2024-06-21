import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'search.dart';

class FoodData {
  FoodData(this.calorie, this.protein);
  final double calorie;
  final double protein;
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
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
    double targetCalories = 1200;
    double targetProtein = 100;

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
                  maximum: targetCalories + 500,
                  majorTickStyle: const MajorTickStyle(color: Colors.white),
                  minorTickStyle: const MinorTickStyle(color: Colors.white),
                  axisLabelStyle: const GaugeTextStyle(color: Colors.white),
                  pointers: [
                    RangePointer(
                      gradient: const SweepGradient(colors: <Color>[
                        Color.fromARGB(255, 195, 0, 255),
                        Color.fromARGB(255, 72, 255, 0),
                        Color.fromARGB(255, 251, 255, 0),
                        Color.fromARGB(255, 255, 0, 0)
                      ], stops: <double>[
                        0,
                        0.25,
                        0.75,
                        1
                      ]),
                      value: consumedCalories,
                    ),
                  ],
                  annotations: [
                    GaugeAnnotation(
                        widget: Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(consumedCalories.toString() + "KCal",
                              style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                    )),
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
                  maximum: targetProtein + 30,
                  majorTickStyle: const MajorTickStyle(color: Colors.white),
                  minorTickStyle: const MinorTickStyle(color: Colors.white),
                  axisLabelStyle: const GaugeTextStyle(color: Colors.white),
                  pointers: [
                    RangePointer(
                      gradient: const SweepGradient(colors: <Color>[
                        Color.fromARGB(255, 255, 0, 0),
                        Color.fromARGB(255, 251, 255, 0),
                        Color.fromARGB(255, 72, 255, 0),
                        Color.fromARGB(255, 195, 0, 255)
                      ], stops: <double>[
                        0,
                        50,
                        75,
                        100
                      ]),
                      value: consumedProteins,
                    ),
                  ],
                  annotations: [
                    GaugeAnnotation(
                        widget: Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(consumedProteins.toString() + "g",
                              style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                    ))
                  ],
                )
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: FloatingActionButton.extended(
          label: const Text(
            "Add Food",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
          backgroundColor: Colors.grey[850],
          onPressed: () {
            print("loading search");
            Navigator.push(
                context, MaterialPageRoute(builder: (context) => Search()));
          },
          icon: const Icon(
            Icons.add_circle_outline,
            size: 50,
            color: Colors.green,
          )),
    );
  }
}
