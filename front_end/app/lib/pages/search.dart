import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  @override
  Widget build(BuildContext context) {
    return (Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
            backgroundColor: Colors.grey[850],
            title: const Text('NutriBoom'),
            centerTitle: true,
            titleTextStyle: const TextStyle(color: Colors.green, fontSize: 40)),
        body: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          //crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: TextField(
                  style: TextStyle(color: Colors.white, fontSize: 20),
                  decoration: InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 15.0),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide(width: 0.8)),
                      hintText: "Search Food Item",
                      hintStyle:
                          TextStyle(color: Colors.grey[500], fontSize: 20),
                      prefixIcon:
                          Icon(Icons.search, size: 30, color: Colors.grey[500]),
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.cancel,
                          size: 30,
                          color: Colors.grey[500],
                        ),
                        onPressed: () => {},
                      )),
                ),
              ),
            )
          ],
        )));
  }
}
