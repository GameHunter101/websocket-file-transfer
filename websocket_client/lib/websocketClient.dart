import "dart:async";
import "dart:convert";
import "dart:io";

import "package:path_provider/path_provider.dart";
import "package:web_socket_channel/web_socket_channel.dart";

class WebSocketClient {
  WebSocketChannel? _channel = null;

  Future<void> connect(String ip, String id) async {
    if (_channel == null) {
      print("CONNECTING HERE...");
      _channel = WebSocketChannel.connect(Uri.parse("ws://$ip?id=$id"));
    }
    return _channel!.ready;
  }

  void sendText(String message) {
    _channel!.sink.add(message);
    addToHistory("text", message);
  }

  /* Future<void> sendFile(Map<String, String> metadata, List<int> file) {
    final completer = Completer<void>();
    final encodedMetadata = utf8.encode(jsonEncode(metadata));
    ByteData metadataLength = ByteData(4);
    metadataLength.setUint32(0, encodedMetadata.length, Endian.little);
    List<int> metaDataLengthBytes = metadataLength.buffer.asUint8List();
    print(DateTime.now().toIso8601String());
    final encodedFile = metaDataLengthBytes + encodedMetadata + file;
    _channel!.sink.add(encodedFile);
    addToHistory("file", metadata["name"]!);
    completer.complete();
    return completer.future;
  } */

  void closeSink() {
    _channel!.sink.close();
  }

  void addToHistory(String action, String payload) async {
    final path = (await getApplicationSupportDirectory()).path;
    File file = File("$path/history.txt");
    final data = "${DateTime.now().toIso8601String()} $action $payload";
    late String currentFileData;
    if (file.existsSync()) {
      currentFileData = file.readAsStringSync();
    } else {
      currentFileData = "";
    }
    file.writeAsString("$data\n${currentFileData}");
  }

  void sendMessage(dynamic data, Map<String, String> metadata) async {
    final fullData = Map<String, dynamic>.from(metadata)
      ..addAll({"data": data});
    _channel!.sink.add(jsonEncode(fullData));
  }
}
