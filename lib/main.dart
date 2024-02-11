import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:quotes_widget/api_keys.dart';
import 'package:home_widget/home_widget.dart';
import 'package:workmanager/workmanager.dart';

const fetchBackground = 'fetchBackground';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    //FlutterBackgroundService.initialize(onStart);
    switch (task) {
      case fetchBackground:
        updateQuote();
        break;
    }
    updateQuote();
    return Future.value(true);
  });
}

void SchedulePeriodicTask() {
  Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  Workmanager().registerPeriodicTask(
    "1",
    fetchBackground,
    frequency: Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SchedulePeriodicTask();
  HomeWidget.registerInteractivityCallback(interactivityCallback);
  runApp(const MyApp());
}

@pragma('vm:entry-point')
Future<void> interactivityCallback(Uri? uri) async {
  if (uri?.host == 'refresh') {
    updateQuote();
    print("Refreshed");
  } else {
    print("Unknown uri: $uri");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quotes Widget For Android',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Famous Quotes'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

void updateQuote() async {
  final quote = await fetchQuote();
  HomeWidget.saveWidgetData<String>('quote', quote.quote);
  HomeWidget.saveWidgetData<String>('author', quote.author.author);
  HomeWidget.updateWidget(
    name: 'QuoteWidget',
    iOSName: 'QuoteWidget',
    androidName: 'QuoteWidget',
  );
}

class Quote {
  final String quote;
  final Author author;

  const Quote({required this.quote, required this.author});
  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
        quote: json['content'] ?? 'Null',
        author: Author.fromJson(json['originator']));
  }
}

class Author {
  final String author;

  Author({required this.author});
  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(author: json['name'] ?? 'Null');
  }
}

Future<Quote> fetchQuote() async {
  final response = await http.get(
      Uri.parse('https://quotes15.p.rapidapi.com/quotes/random/?'),
      headers: {
        "x-rapidapi-host": "quotes15.p.rapidapi.com",
        "x-rapidapi-key": apikey
      });
  if (response.statusCode == 200) {
    return Quote.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load quote');
  }
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: FutureBuilder<Quote>(
          future: fetchQuote(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Center(
                child: Card(
                  margin: const EdgeInsets.fromLTRB(40, 200, 40, 200),
                  child: Column(
                    children: <Widget>[
                      Text(snapshot.data!.quote),
                      Text(snapshot.data!.author.author),
                      ElevatedButton(
                        onPressed: () {
                          updateQuote();
                        },
                        child: const Text('Refresh Widget'),
                      ),
                    ],
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }
            return const CircularProgressIndicator();
          },
        ));
  }
}
