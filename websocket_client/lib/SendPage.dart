import "dart:io";

import "package:file_picker/file_picker.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:websocket_client/main.dart";
import 'package:websocket_client/websocketClient.dart';
import "package:http/http.dart" as http;

class SendPage extends StatefulWidget {
  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  var fileTransfer = true;
  String? id = null;
  String? ip = null;
  final WebSocketClient webSocket = WebSocketClient();

  final recipientAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // webSocket = WebSocketClient("ws://192.168.1.16:60116");
  }

  @override
  void dispose() {
    super.dispose();
    // webSocket.closeSink();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var headerStyle = theme.textTheme.displayMedium!
        .copyWith(color: theme.colorScheme.onPrimaryContainer);
    var appState = context.watch<MainState>();

    return Builder(builder: (context) {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Send Data", style: headerStyle),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Form(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 300),
                      child: TextFormField(
                        controller: recipientAddressController,
                        decoration: InputDecoration(
                          hintText: "Recipient IP and port: ",
                          suffix: IconButton(
                            icon: Icon(Icons.send),
                            onPressed: _establishConnection,
                          ),
                        ),
                        onFieldSubmitted: (value) {
                          _establishConnection();
                        },
                      ),
                    ),
                  ),
                ),
              ),
              if (ip != null && id != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      TextButton(
                          style: ButtonStyle(
                            backgroundColor: fileTransfer
                                ? MaterialStateProperty.all<Color>(
                                    theme.colorScheme.surfaceVariant)
                                : MaterialStateProperty.all<Color>(
                                    Colors.transparent),
                          ),
                          child: Text("File"),
                          onPressed: () {
                            setState(() {
                              fileTransfer = true;
                            });
                          }),
                      TextButton(
                          style: ButtonStyle(
                            backgroundColor: !fileTransfer
                                ? MaterialStateProperty.all<Color>(
                                    theme.colorScheme.surfaceVariant)
                                : MaterialStateProperty.all<Color>(
                                    Colors.transparent),
                          ),
                          child: Text("Text"),
                          onPressed: () {
                            setState(() {
                              fileTransfer = false;
                            });
                          }),
                    ]),
                  ),
                ),
            ],
          ),
          if (ip != null && id != null)
            TransferData(
              fileTransfer: fileTransfer,
              id: id!,
              ip: ip!,
              webSocket: webSocket,
            )
        ],
      ));
    });
  }

  void _establishConnection() async {
    print("sending request...");
    var response =
        await http.get(Uri.parse("http://${recipientAddressController.text}"));
    setState(() {
      if (response.statusCode != HttpStatus.forbidden) {
        id = response.body;
        ip = recipientAddressController.text;
      }
    });
    print("Response: ${id}");
  }
}

class TransferData extends StatefulWidget {
  final String ip;
  final String id;
  final bool fileTransfer;
  final WebSocketClient webSocket;
  TransferData({
    required this.fileTransfer,
    required this.id,
    required this.ip,
    required this.webSocket,
  });

  @override
  State<TransferData> createState() => _TransferDataState();
}

class _TransferDataState extends State<TransferData> {
  var fileData = new Uint8List(0);
  Map<String, String> metadata = {};
  final textFormController = TextEditingController();

  String insertCharAtIndex(String original, int index, String insert) {
    if (index < 0 || index >= original.length) {
      return original;
    }

    return original.substring(0, index) + insert + original.substring(index);
  }

  @override
  void dispose() {
    super.dispose();
    widget.webSocket.closeSink();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var infoStyle =
        theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.primary);
    return FutureBuilder(
      future: widget.webSocket.connect(widget.ip, widget.id),
      builder: (context, snapshot) {
        return Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Card(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 40, right: 40, top: 20, bottom: 20),
                  child: widget.fileTransfer
                      ? Row(
                          children: [
                            Expanded(
                              child: IconButton(
                                icon: Icon(Icons.file_open, size: 50),
                                onPressed: () async {
                                  final result =
                                      await FilePicker.platform.pickFiles(
                                    type: FileType.any,
                                    allowMultiple: false,
                                  );
                                  if (result == null || result.files.isEmpty) {
                                    return;
                                  }
                                  final selectedFile = result.files.single;
                                  if (selectedFile.path != null) {
                                    final fileContent =
                                        await File(selectedFile.path!)
                                            .readAsBytes();
                                    fileData = fileContent;
                                    var sizeLabel = "";
                                    var sizeDivision = 1;
                                    if (selectedFile.size < 1000000) {
                                      if (selectedFile.size < 1000) {
                                        sizeLabel = " B";
                                      } else {
                                        sizeLabel = " KB";
                                        sizeDivision = 1000;
                                      }
                                    } else {
                                      sizeLabel = " MB";
                                      sizeDivision = 1000000;
                                    }
                                    setState(() {
                                      metadata = {
                                        "name": selectedFile.name.split(".")[0],
                                        "extension": selectedFile.extension!,
                                        "size":
                                            (selectedFile.size / sizeDivision)
                                                    .toStringAsPrecision(4)
                                                    .toString() +
                                                sizeLabel,
                                      };
                                    });
                                  } else {
                                    print("selected file path is null");
                                  }
                                },
                              ),
                            ),
                            if (metadata.isNotEmpty)
                              Row(
                                children: [
                                  SizedBox(width: 10),
                                  Container(
                                    width: 150,
                                    child: Column(
                                      children: [
                                        Text(
                                          "Name: ${insertCharAtIndex(metadata["name"]!, 12, " ")}\n",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: infoStyle,
                                        ),
                                        Text(
                                          "Type: ${metadata["extension"]}\n",
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: infoStyle,
                                        ),
                                        Text(
                                          "Size: ${metadata["size"]}",
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: infoStyle,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        )
                      : Form(
                          child: TextFormField(
                            controller: textFormController,
                            decoration: const InputDecoration(
                                hintText: "Send a message: "),
                            onFieldSubmitted: (value) {
                              // channel.sink.add(value);
                              // print(value);
                              setState(() {
                                metadata = {
                                  "name": "TEXT",
                                  "extension": "TEXT",
                                  "size": "TEXT"
                                };
                              });
                              widget.webSocket.sendMessage(
                                  textFormController.text, metadata);
                              setState(() {
                                metadata = {};
                              });
                              // webSocket.sendText(value);
                              textFormController.clear();
                            },
                          ),
                        ),
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: TextButton.icon(
                  icon: Icon(Icons.send),
                  label: Text("Send"),
                  onPressed: () async {
                    if (widget.fileTransfer) {
                      widget.webSocket.sendMessage(fileData, metadata);
                      // webSocket.sendFile(fileMetaData, fileData);
                    } else {
                      setState(() {
                        metadata = {
                          "name": "TEXT",
                          "extension": "TEXT",
                          "size": "TEXT"
                        };
                      });
                      widget.webSocket
                          .sendMessage(textFormController.text, metadata);
                      // webSocket.sendText(textFormController.text);
                      textFormController.clear();
                    }
                    setState(() {
                      metadata = {};
                    });
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
