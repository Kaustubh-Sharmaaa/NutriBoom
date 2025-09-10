import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Configure the API base URL via --dart-define=API_BASE_URL=...
const String _base = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000');

class FoodItem {
  final String name;
  final double calorie;
  final double protein;
  final double? carbs;
  final double? fat;
  final String? per; // e.g., per 100g
  final double? servingSize; // e.g., 1 (serving) or 100 (g)
  final String? servingUnit; // e.g., serving, g
  FoodItem({
    required this.name,
    required this.calorie,
    required this.protein,
    this.carbs,
    this.fat,
    this.per,
    this.servingSize,
    this.servingUnit,
  });
  factory FoodItem.fromJson(Map<String, dynamic> j) => FoodItem(
        name: j['name'] as String,
        calorie: (j['calorie'] as num).toDouble(),
        protein: (j['protein'] as num).toDouble(),
        carbs: j['carbs'] == null ? null : (j['carbs'] as num).toDouble(),
        fat: j['fat'] == null ? null : (j['fat'] as num).toDouble(),
        per: j['per'] as String?,
        servingSize: j['servingSize'] == null ? null : (j['servingSize'] as num).toDouble(),
        servingUnit: j['servingUnit'] as String?,
      );
}

class Totals {
  final double consumedCalories;
  final double consumedProtein;
  final double targetCalories;
  final double targetProtein;
  final List<ConsumedEntry> entries;
  Totals({required this.consumedCalories, required this.consumedProtein, required this.targetCalories, required this.targetProtein, required this.entries});
  factory Totals.fromJson(Map<String, dynamic> j) => Totals(
        consumedCalories: (j['consumedCalories'] as num).toDouble(),
        consumedProtein: (j['consumedProtein'] as num).toDouble(),
        targetCalories: (j['targetCalories'] as num).toDouble(),
        targetProtein: (j['targetProtein'] as num).toDouble(),
        entries: ((j['entries'] as List<dynamic>? ) ?? const []).map((e) => ConsumedEntry.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class ConsumedEntry {
  final String name;
  final double calorie;
  final double protein;
  final double? amount;
  final double? servingSize;
  final String? servingUnit;
  ConsumedEntry({required this.name, required this.calorie, required this.protein, this.amount, this.servingSize, this.servingUnit});
  factory ConsumedEntry.fromJson(Map<String, dynamic> j) => ConsumedEntry(
        name: j['name'] as String,
        calorie: (j['calorie'] as num?)?.toDouble() ?? 0.0,
        protein: (j['protein'] as num?)?.toDouble() ?? 0.0,
        amount: (j['amount'] as num?)?.toDouble(),
        servingSize: (j['servingSize'] as num?)?.toDouble(),
        servingUnit: j['servingUnit'] as String?,
      );
}

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? _base,
        _client = client ?? http.Client();

  Uri _u(String p, [Map<String, dynamic>? q]) => Uri.parse('$baseUrl$p').replace(queryParameters: q?.map((k, v) => MapEntry(k, '$v')));

  Future<Totals> getTotals() async {
    final r = await _client.get(_u('/api/consumed'));
    if (r.statusCode != 200) throw Exception('Failed to load totals');
    return Totals.fromJson(json.decode(r.body) as Map<String, dynamic>);
  }

  Future<List<FoodItem>> searchFoods(String q) async {
    final r = await _client.get(_u('/api/foods', {'q': q}));
    if (r.statusCode != 200) throw Exception('Failed to search foods');
    final list = json.decode(r.body) as List<dynamic>;
    return list.map((e) => FoodItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Totals> addConsumed(FoodItem item, double amount) async {
    final r = await _client.post(_u('/api/consume'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': item.name,
          // Use detailed payload for scalable edits later
          'amount': amount,
          'servingSize': item.servingSize ?? (item.per == '100g' ? 100 : 1),
          'servingUnit': item.servingUnit ?? (item.per == '100g' ? 'g' : 'serving'),
          'per': item.per,
          'baseCalorie': item.calorie,
          'baseProtein': item.protein,
        }));
    if (r.statusCode != 200) throw Exception('Failed to add consumed');
    return Totals.fromJson(json.decode(r.body) as Map<String, dynamic>);
  }

  Future<Totals> deleteConsumed(int index) async {
    final r = await _client.delete(_u('/api/consume/$index'));
    if (r.statusCode != 200) throw Exception('Failed to delete consumed');
    return Totals.fromJson(json.decode(r.body) as Map<String, dynamic>);
  }

  Future<Totals> updateConsumed(int index, double amount) async {
    final r = await _client.put(_u('/api/consume/$index'), headers: {'Content-Type': 'application/json'}, body: json.encode({'amount': amount}));
    if (r.statusCode != 200) throw Exception('Failed to update consumed');
    return Totals.fromJson(json.decode(r.body) as Map<String, dynamic>);
  }
}
