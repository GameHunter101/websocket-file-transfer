import 'dart:io';

import 'package:path_provider/path_provider.dart';

class History {

  Future<List<String>> readFile() async {
    final file = await loadFile();
    return file.readAsLinesSync();
  }

  Future<File> loadFile() async {
    final path = (await getApplicationSupportDirectory()).path+"/history.txt";
    final file = File(path);
    if (!file.existsSync()) {
      file.create();
    }
    return file;
  }

  clearFile() async{
    final file = await loadFile();
    file.writeAsString("");
  }
}