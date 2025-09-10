import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'search.dart';
import '../services/api.dart';

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
  final _api = ApiClient();
  bool _loading = true;
  double consumedCalories = 0;
  double consumedProteins = 0;
  double targetCalories = 1200;
  double targetProtein = 100;
  List<ConsumedEntry> entries = [];

  @override
  void initState() {
    super.initState();
    _refreshTotals();
  }

  Future<void> _refreshTotals() async {
    setState(() => _loading = true);
    try {
      final t = await _api.getTotals();
      setState(() {
        consumedCalories = t.consumedCalories;
        consumedProteins = t.consumedProtein;
        targetCalories = t.targetCalories;
        targetProtein = t.targetProtein;
        entries = t.entries;
      });
    } catch (e) {
      // Keep simple: ignore error UI for now
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
          backgroundColor: Colors.grey[850],
          title: const Text('NutriBoom'),
          centerTitle: true,
          titleTextStyle: const TextStyle(color: Colors.green, fontSize: 40)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
      // Consumed list with edit/delete
      bottomSheet: _loading
          ? null
          : Container(
              color: Colors.grey[900],
              height: MediaQuery.of(context).size.height * 0.4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('Today\'s items', style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final e = entries[i];
                        final unitLabel = (e.amount != null && e.servingUnit != null)
                            ? '${e.amount!.toStringAsFixed(0)} ${e.servingUnit}'
                            : '';
                        return ListTile(
                          title: Text(e.name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(
                            '${e.calorie.toStringAsFixed(0)} kcal • ${e.protein.toStringAsFixed(1)} g  ${unitLabel.isNotEmpty ? '• $unitLabel' : ''}',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.amber),
                                  onPressed: () => _editAmount(i, e)),
                              IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => _deleteEntry(i)),
                            ],
                          ),
                        );
                      },
                    ),
                  )
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Search(onAdded: _refreshTotals)),
            );
          },
          icon: const Icon(
            Icons.add_circle_outline,
            size: 50,
            color: Colors.green,
          )),
    );
  }

  Future<void> _deleteEntry(int index) async {
    setState(() => _loading = true);
    try {
      final t = await _api.deleteConsumed(index);
      setState(() {
        consumedCalories = t.consumedCalories;
        consumedProteins = t.consumedProtein;
        targetCalories = t.targetCalories;
        targetProtein = t.targetProtein;
        entries = t.entries;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editAmount(int index, ConsumedEntry entry) async {
    final controller = TextEditingController(text: (entry.amount ?? entry.servingSize ?? 1).toString());
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text('Update amount', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Amount', hintStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.green))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                final v = double.tryParse(controller.text.trim());
                if (v != null && v > 0) Navigator.pop(context, v);
              },
              child: const Text('Save'))
        ],
      ),
    );
    if (amount == null) return;
    setState(() => _loading = true);
    try {
      final t = await _api.updateConsumed(index, amount);
      setState(() {
        consumedCalories = t.consumedCalories;
        consumedProteins = t.consumedProtein;
        targetCalories = t.targetCalories;
        targetProtein = t.targetProtein;
        entries = t.entries;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
