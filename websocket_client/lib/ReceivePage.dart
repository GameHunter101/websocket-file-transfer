import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
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
  final ValueNotifier<Map<String, dynamic>?> newMessage =
      ValueNotifier<Map<String, dynamic>?>(null);
  String? messageName = null;
  String? messageExtension = null;
  String? messageSize = null;
  dynamic messageData = null;
  Type? messageType = null;
  String? mimeType = null;

  GlobalKey columnKey = GlobalKey();
  late double imageHeight;

  late Uint8List fileBytes;

  String insertCharAtIndex(String original, int index, String insert) {
    if (index < 0 || index >= original.length) {
      return original;
    }

    return original.substring(0, index) + insert + original.substring(index);
  }

  @override
  void initState() {
    super.initState();
    newMessage.addListener(() {
      print("new message!");
      setState(() {
        if (newMessage.value != null) {
          messageName = newMessage.value!["name"];
          messageExtension = newMessage.value!["extension"];
          messageSize = newMessage.value!["size"];
          messageData = newMessage.value!["data"];
          messageType = newMessage.value!["data"].runtimeType;
          if (messageType != String) {
            List<int> tempIntList = new List<int>.from(messageData);
            fileBytes = Uint8List.fromList(tempIntList);
            mimeType = lookupMimeType("$messageName.$messageExtension",
                headerBytes: fileBytes);
            print(mimeType);
          }
        }
      });
    });

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
          widget.websocketServer.upgradeConnection(request, newMessage);
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
    final maxHeight = MediaQuery.of(context).size.height;
    final keyContext = columnKey.currentContext;
    late final RenderBox box;
    if (keyContext != null) {
      box = (keyContext.findRenderObject() as RenderBox);
      imageHeight = (maxHeight - box.size.height);
    }

    return Container(
      height: MediaQuery.of(context).size.height,
      child: Column(
        // mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            key: columnKey,
            mainAxisSize: MainAxisSize.min,
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
                                "IP: ${widget.snapshotData.address}",
                                style: infoStyle,
                              ),
                              Text(
                                "Port #: ${widget.snapshotData.port}",
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
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black),
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
                              SizedBox(
                                width: 10,
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
              if (newMessage.value != null && messageType != String)
                Container(
                  width: 400,
                  child: Row(
                    children: [
                      Container(
                        width: 150,
                        child: Column(
                          children: [
                            Text(
                              "Name: ${insertCharAtIndex(messageName!, 12, " ")}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: infoStyle,
                            ),
                            Text(
                              "Type: ${messageExtension}",
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: infoStyle,
                            ),
                            Text(
                              "Size: ${messageSize}",
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: infoStyle,
                            ),
                          ],
                        ),
                      ),
                      if (messageType != String)
                        Row(
                          children: [
                            SizedBox(
                              width: 50,
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await FilePicker.platform
                                    .getDirectoryPath(
                                        initialDirectory:
                                            (await getApplicationDocumentsDirectory())
                                                .path);
                                if (result == null) {
                                  return;
                                }
                                final file = File(
                                    "$result\\$messageName.$messageExtension");
                                file.create().then(
                                    (value) => value.writeAsBytes(fileBytes));
                              },
                              icon: Icon(Icons.download),
                              label: Text("Download file"),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
            ],
          ),
          if (newMessage.value != null &&
              mimeType != null &&
              mimeType!.contains("image"))
            FutureBuilder(
              future: _waitUntilDisplayed(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return CircularProgressIndicator();
                }
                final maxHeight = MediaQuery.of(context).size.height;
                final keyContext = columnKey.currentContext;
                late final RenderBox box;
                if (keyContext != null) {
                  box = (keyContext.findRenderObject() as RenderBox);
                  imageHeight = maxHeight - box.size.height;
                }
                return Padding(
                  padding: EdgeInsets.only(
                    top: imageHeight.abs() * 0.05,
                    bottom: imageHeight.abs() * 0.05,
                  ),
                  child: Image.memory(
                    fileBytes,
                    height: imageHeight.abs() * 0.9,
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
          if (messageType == String)
            Text(
              messageData,
            ),
        ],
      ),
    );
  }

  Future<void> _waitUntilDisplayed() async {
    await Future.delayed(Duration.zero);
    await Future(() {});
  }
}
