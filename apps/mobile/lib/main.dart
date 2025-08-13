import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navigation Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  // Const list so the constructor can remain const
  final List<String> screens = const [
    "Screen One",
    "Screen Two",
    "Screen Three",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: screens.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TemplateScreen(screenTitle: screens[index]),
                  ),
                );
              },
              child: Text("Go to ${screens[index]}"),
            ),
          );
        },
      ),
    );
  }
}

// Simple placeholder screen template
class TemplateScreen extends StatelessWidget {
  final String screenTitle;
  const TemplateScreen({super.key, required this.screenTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(screenTitle)),
      body: Center(
        child: Text(screenTitle, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}
