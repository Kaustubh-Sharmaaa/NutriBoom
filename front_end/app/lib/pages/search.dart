import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api.dart';

class Search extends StatefulWidget {
  final Future<void> Function()? onAdded;
  const Search({super.key, this.onAdded});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final _api = ApiClient();
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  List<FoodItem> _results = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _search);
  }

  Future<void> _search() async {
    final q = _controller.text.trim();
    setState(() => _loading = true);
    try {
      final list = await _api.searchFoods(q);
      setState(() => _results = list);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add(FoodItem item) async {
    // Backward-compat: route to new prompt-and-add flow
    await _promptAmountAndAdd(item);
  }
  @override
  Widget build(BuildContext context) {
    return (Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
            backgroundColor: Colors.grey[850],
            title: const Text('NutriBoom'),
            centerTitle: true,
            titleTextStyle: const TextStyle(color: Colors.green, fontSize: 40)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 20),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 16),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0), borderSide: const BorderSide(width: 0.8)),
                  hintText: "Search Food Item",
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 18),
                  prefixIcon: Icon(Icons.search, size: 24, color: Colors.grey[500]),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(Icons.cancel, size: 22, color: Colors.grey[500]),
                          onPressed: () => _controller.clear(),
                        ),
                ),
              ),
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final f = _results[i];
                  return ListTile(
                    title: Text(f.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      _subtitleFor(f),
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                      onPressed: () => _promptAmountAndAdd(f),
                    ),
                  );
                },
              ),
            )
          ],
        )));
  }

  String _subtitleFor(FoodItem f) {
    final parts = <String>[
      '${f.calorie.toStringAsFixed(0)} kcal',
      '${f.protein.toStringAsFixed(1)} g protein',
      if (f.carbs != null) '${f.carbs!.toStringAsFixed(1)} g carbs',
      if (f.fat != null) '${f.fat!.toStringAsFixed(1)} g fat',
    ];
    final per = f.per != null ? ' per ${f.per}' : '';
    return parts.join(' • ') + per;
  }

  Future<void> _promptAmountAndAdd(FoodItem item) async {
    final unit = item.servingUnit ?? (item.per == '100 g' ? 'g' : 'serving');
    final baseSize = item.servingSize ?? (unit == 'g' ? 100 : 1);
    final controller = TextEditingController(text: unit == 'g' ? '100' : '1');

    final amount = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[850],
          title: Text('Enter amount', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Unit: $unit (base ${baseSize.toStringAsFixed(0)} $unit)', style: TextStyle(color: Colors.grey[400])),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Amount', hintStyle: TextStyle(color: Colors.grey), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)), focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.green))),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final v = double.tryParse(controller.text.trim());
                if (v != null && v > 0) Navigator.pop(context, v);
              },
              child: const Text('Add'),
            )
          ],
        );
      },
    );

    if (amount != null) {
      await _addWithAmount(item, amount);
    }
  }

  Future<void> _addWithAmount(FoodItem item, double amount) async {
    setState(() => _loading = true);
    try {
      await _api.addConsumed(item, amount);
      if (widget.onAdded != null) await widget.onAdded!();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }
}
