import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:websocket_client/HistoryPage.dart";
import "package:websocket_client/ReceivePage.dart";

import "SendPage.dart";

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MainState(),
      child: MaterialApp(
        title: "Websocket File Transfer",
        theme: ThemeData(
          useMaterial3: true,
          colorScheme:
              ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 194, 72, 72)),
        ),
        home: HomePage(),
      ),
    );
  }
}

class MainState extends ChangeNotifier {}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var destinationIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (destinationIndex) {
      case 0:
        page = SendPage();
        break;
      case 1:
        page = ReceivePage();
        break;
      case 2:
        page = HistoryPage();
        break;
      default:
        page = Text("Invalid destination index");
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                backgroundColor: Theme.of(context).colorScheme.background,
                extended: constraints.maxWidth >= 600,
                minExtendedWidth: 175,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.call_made),
                    label: Text("Send",
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer)),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.call_received),
                    label: Text("Receive",
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer)),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.history),
                    label: Text("History",
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer)),
                  ),
                ],
                selectedIndex: destinationIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    destinationIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}