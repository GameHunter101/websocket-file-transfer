import "dart:io";
// import "package:connectivity_plus/connectivity_plus.dart";
// import "package:data_connection_checker/data_connection_checker.dart";

class WebSocketServer {
  late final HttpServer server;

  Future<Tuple<String,int>> initializeServer() async {
    late String ip;
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        if (addr.address.contains("192.168")) {
          ip = addr.address;
        }
      }
    }
    try {

    server = await HttpServer.bind(ip, 0);
    } catch (e) {
      print("Server is already initialized");
    }
    return Tuple(ip, server.port);
  }
}

class Tuple<X,Y> {
  final X address;
  final Y port;

  Tuple(this.address,this.port);
}