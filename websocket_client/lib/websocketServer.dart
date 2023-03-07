import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:math";

class WebSocketServer {
  late final HttpServer server;
  String? senderId = null;
  String? senderIp = null;

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
      server = await HttpServer.bind(_ip, port);

      // server.listen(_handleConnection);
    } catch (e) {
      print("Server is already initialized, $e");
    }
    return Tuple(_ip, port);
  }

  Future<int> getOpenPort(String address) async {
    ServerSocket socket = await ServerSocket.bind(address, 0);
    int port = socket.port;
    socket.close();
    return port;
  }

  void handleConnection(HttpRequest request) async {
    senderIp = request.connectionInfo?.remoteAddress.address;
    print("connection!!");
    final params = request.uri.queryParameters;
    if (params.keys.contains("id") && params["id"] == senderId) {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        WebSocket webSocket = await WebSocketTransformer.upgrade(request);
        _handleWebSocket(webSocket);
      } else {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.close();
      }
    } else {
      senderId = _generateId(14);
      request.response.write(senderId);
      request.response.close();
    }
  }

  void _handleWebSocket(WebSocket ws) {
    ws.listen((data) {
      print("Received data: ${jsonDecode(data)}");
      // ws.add("Received: $data");
    }, onDone: () {
      print("User disconnected");
    }, onError: (error) {
      print("Error: $error");
    });
  }

  String _generateId(int length) {
    final random = Random();
    const chars =
        "`1234567890-=qwertyuiop[]asdfghjkl;zxcvbnm,./~!@#%^&*()_+QWERTYUIOP{}|ASDFGHJKL:ZXCVBNM<>?";
    final test = String.fromCharCodes(Iterable.generate(
      length,
      (index) => chars.codeUnitAt(random.nextInt(chars.length)),
    ));
    return test;
  }

  void closeServer() {
    server.close();
    print("Server closed");
  }
}

class Tuple<X, Y> {
  final X address;
  final Y port;

  Tuple(this.address, this.port);
}
