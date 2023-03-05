import "dart:async";
import "dart:io";
import "dart:math";

// import "package:shelf/shelf.dart";
import "package:shelf/shelf_io.dart" as shelf;
import "package:shelf_web_socket/shelf_web_socket.dart";
import "package:shelf_plus/shelf_plus.dart";
// import "package:connectivity_plus/connectivity_plus.dart";
// import "package:data_connection_checker/data_connection_checker.dart";

class WebSocketServer {
  late final HttpServer _server;
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
      var cascade = Cascade().add(webSocketHandler(_handleWebSocket));
      // .add(_echoRequest);

      _server = await shelf.serve(cascade.handler, _ip, await getOpenPort(_ip));
      final server = await HttpServer.bind(_ip, port);
      print("Serving at ws://${_server.address.host}:${port}");

      server.listen(_handleConnection);
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

  /* FutureOr<void> _handleWebSocket(ws) {
    print("connected");

    ws.stream.listen((message) {
      print("Received message from $senderId: $message");
    }, onDone: () {
      senderId = null;
      senderIp = null;
      print("Client disconnected");
    });
    return null;
  } */

  void _handleConnection(HttpRequest request) async {
    senderIp = request.connectionInfo?.remoteAddress.address;
    print("connection!!");
    final params = request.uri.queryParameters;
    print("${params["id"]}, $senderId, ${params["id"] == senderId}");
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
      request.response.write("IP: $senderIp, ID: $senderId");
      request.response.close();
    }
  }

  void _handleWebSocket(WebSocket ws) {
    ws.listen((data) {
      print("Received data: $data");
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
    _server.close();
    print("Server closed");
  }
}

class Tuple<X, Y> {
  final X address;
  final Y port;

  Tuple(this.address, this.port);
}

/* class WsController extends WebSocketController {
  WsController(AngelWebSocket ws):super(ws);

  @override
  void onConnect(WebSocketContext socket) {
    print("connected!");
  }

  
} */