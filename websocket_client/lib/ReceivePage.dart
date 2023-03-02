import 'package:flutter/material.dart';
import 'package:websocket_client/websocketServer.dart';

class ReceivePage extends StatefulWidget {
  const ReceivePage({
    super.key,
  });

  @override
  State<ReceivePage> createState() => _ReceivePageState();
}

class _ReceivePageState extends State<ReceivePage> {
  final websocketServer = WebSocketServer();

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var headerStyle = theme.textTheme.displayMedium!
        .copyWith(color: theme.colorScheme.onPrimaryContainer);
    var infoStyle =
        theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.primary);
    return FutureBuilder(
      future: websocketServer.initializeServer(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Receive Data", style: headerStyle),
              ),
              Card(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 400),
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 40, right: 40, top: 20, bottom: 20),
                    child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text("Ip: ${snapshot.data!.address}", style: infoStyle,),
                                Text("Port: ${snapshot.data!.port}", style: infoStyle,),
                              ],
                            )
                          ),
                          
                        ],
                      )
                  ),
                ),
              ),
            ],
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
