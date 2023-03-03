import "dart:async";
import "dart:io";

import "package:shelf/shelf_io.dart" as shelf;
import "package:shelf_web_socket/shelf_web_socket.dart";
import "package:websocket_client/noDartHtml.dart";

class WebSocketServer {
  late final HttpServer _server;
  Future<Tuple<String, int>> initializeServer() async {
    late String _ip;
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.address.contains("192.168")) {
          _ip = addr.address;
        }
      }
    }
    final port = await getOpenPort(_ip);

    try {
      var handler = webSocketHandler((webSocket) {
        webSocket.stream.listen((message) {
          print("MESSAGE RECEIVED: $message");
        });
      });

      _server =
          await shelf.serve(webSocketHandler(_handleWebSocket), _ip, port);
      print("Serving at ws://${_server.address.host}:${_server.port}");
    } catch (e) {
      print("Server is already initialized");
    }
    return Tuple(_ip, port);
  }

  Future<int> getOpenPort(String address) async {
    ServerSocket socket = await ServerSocket.bind(address, 0);
    int port = socket.port;
    socket.close();
    return port;
  }

  FutureOr<void> _handleWebSocket(HtmlWebSocketChannel ws) {
    print("Client Connected");

    ws.stream.listen((message) {
      print("Received message: $message");
    }, onDone: () {
      print("Client disconnected");
    });
    return null;
  }

  void closeServer() {
    _server.close();
    print("Server closed");
  }
}

class Tuple<X, Y> {
  final X address;
  final Y port;

  Tuple(this.address, this.port);
}
