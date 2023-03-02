import "dart:io";
import "dart:typed_data";

import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:websocket_client/main.dart";
import "package:websocket_client/ws.dart";

class SendPage extends StatefulWidget {
  @override
  State<SendPage> createState() => _SendPageState();
}

class _SendPageState extends State<SendPage> {
  var fileTransfer = true;
  var fileData = new Uint8List(0);
  late final WebSocketGen webSocket;
  Map<String, String> fileMetaData = {};

  final textFormController = TextEditingController();

  @override
  void initState() {
    super.initState();
    webSocket = WebSocketGen("ws://192.168.1.16:60116");
  }

  @override
  void dispose() {
    super.dispose();
    webSocket.closeSink();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var headerStyle = theme.textTheme.displayMedium!
        .copyWith(color: theme.colorScheme.onPrimaryContainer);
    var infoStyle =
        theme.textTheme.bodyMedium!.copyWith(color: theme.colorScheme.primary);
    var appState = context.watch<MainState>();

    String insertCharAtIndex(String original, int index, String insert) {
      if (index < 0 || index >= original.length) {
        return original;
      }

      return original.substring(0, index) + insert + original.substring(index);
    }

    return Builder(builder: (context) {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Send Data", style: headerStyle),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                TextButton(
                    child: Text("File"),
                    onPressed: () {
                      setState(() {
                        fileTransfer = true;
                      });
                    }),
                TextButton(
                    child: Text("Text"),
                    onPressed: () {
                      setState(() {
                        fileTransfer = false;
                      });
                    }),
              ]),
            ),
          ),
          Card(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 40, right: 40, top: 20, bottom: 20),
                child: fileTransfer
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
                                    fileMetaData = {
                                      "name": selectedFile.name.split(".")[0],
                                      "extension": selectedFile.extension!,
                                      "size": (selectedFile.size / sizeDivision)
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
                          if (fileMetaData.isNotEmpty)
                            Row(
                              children: [
                                SizedBox(width: 10),
                                Container(
                                  width: 150,
                                  child: Column(
                                    children: [
                                      Text(
                                        "Name: ${insertCharAtIndex(fileMetaData["name"]!, 12, " ")}\n",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: infoStyle,
                                      ),
                                      Text(
                                        "Type: ${fileMetaData["extension"]}\n",
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: infoStyle,
                                      ),
                                      Text(
                                        "Size: ${fileMetaData["size"]}",
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
                            webSocket.sendText(value);
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
                onPressed: () {
                  if (fileTransfer) {
                    webSocket.sendFile(fileMetaData, fileData);
                  } else {
                    webSocket.sendText(textFormController.text);
                    textFormController.clear();
                  }
                },
              ),
            ),
          ),
        ],
      ));
    });
  }
}
