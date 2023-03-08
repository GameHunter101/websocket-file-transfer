import 'dart:io';

import 'package:websocket_client/websocketServer.dart';
import 'package:flutter/material.dart';

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
  void dispose() {
    super.dispose();
    websocketServer.closeServer();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return FutureBuilder(
      future: websocketServer.initializeServer(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return ServerInfo(
            snapshotData: snapshot.data!,
            websocketServer: websocketServer,
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class ServerInfo extends StatefulWidget {
  final Tuple<String, int> snapshotData;
  final WebSocketServer websocketServer;

  const ServerInfo({
    super.key,
    required this.snapshotData,
    required this.websocketServer,
  });

  @override
  State<ServerInfo> createState() => _ServerInfoState();
}

class _ServerInfoState extends State<ServerInfo> {
  HttpRequest? _incomingRequest = null;

  @override
  void initState() {
    super.initState();
    try {
    widget.websocketServer.server.listen((request) async {
      if (!WebSocketTransformer.isUpgradeRequest(request)) {
        setState(() {
          _incomingRequest = request;
        });
        print(
            "CONNECTION FROM: ${request.connectionInfo?.remoteAddress.address}");
        print(_incomingRequest!.connectionInfo!.remoteAddress.address);
      } else {
        widget.websocketServer.upgradeConnection(request);
      }
    });
    } catch (error) {
      print(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var headerStyle = theme.textTheme.displayMedium!
        .copyWith(color: theme.colorScheme.onPrimaryContainer);
    var infoStyle =
        theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.primary);
    var boldInfoStyle = infoStyle.copyWith(fontWeight: FontWeight.bold);
    return Column(
      mainAxisSize: MainAxisSize.max,
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
                        Text(
                          "Ip: ${widget.snapshotData.address}",
                          style: infoStyle,
                        ),
                        Text(
                          "Port: ${widget.snapshotData.port}",
                          style: infoStyle,
                        ),
                      ],
                    )),
                  ],
                )),
          ),
        ),
        if (_incomingRequest != null)
          Card(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                      children: <TextSpan>[
                        TextSpan(
                          text: "Incoming connection from: ",
                          style: infoStyle,
                        ),
                        TextSpan(
                          text: _incomingRequest
                              ?.connectionInfo?.remoteAddress.address,
                          style: boldInfoStyle,
                        ),
                      ],
                    ),
                    // "Incoming connection from: ${_incomingRequest?.connectionInfo?.remoteAddress.address}",
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _incomingRequest!.response.statusCode =
                                HttpStatus.forbidden;
                            _incomingRequest!.response
                                .write("Connection rejected");
                            _incomingRequest!.response.close();
                            setState(() {
                              _incomingRequest = null;
                            });
                          },
                          child: Text("Reject"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            widget.websocketServer
                                .handleConnection(_incomingRequest!);
                            setState(() {
                              _incomingRequest = null;
                            });
                          },
                          child: Text("Accept"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
