import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:path_provider/path_provider.dart";
import "package:web_socket_channel/web_socket_channel.dart";

class WebSocketClient {
  late WebSocketChannel _channel;
  WebSocketClient(String url)
      : _channel = WebSocketChannel.connect(Uri.parse(url));

  void sendText(String message) {
    _channel.sink.add(message);
    addToHistory("text", message);
  }

  void sendFile(Map<String, String> metadata, List<int> file) {
    final encodedMetadata = utf8.encode(jsonEncode(metadata));
    ByteData metadataLength = ByteData(4);
    metadataLength.setUint32(0, encodedMetadata.length, Endian.little);
    List<int> metaDataLengthBytes = metadataLength.buffer.asUint8List();
    print(DateTime.now().toIso8601String());
    final encodedFile = metaDataLengthBytes + encodedMetadata + file;
    _channel.sink.add(encodedFile);
    addToHistory("file", metadata["name"]!);
  }

  void closeSink() {
    _channel.sink.close();
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
/*     if (!(await file.exists())) {
      print("File does not exist");
      print("creating file...");
      await file.create();
    } else {
      print("file exists");
    } */
  }
}
