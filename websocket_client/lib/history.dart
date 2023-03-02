import 'dart:io';

import 'package:path_provider/path_provider.dart';

class History {
  late final File _historyFile;
  List<String> parsedFile = [];

  History() {
    _loadFile();
  }

  void _loadFile() async {
    _historyFile = File((await getApplicationSupportDirectory()).path+"/history.txt");
    parsedFile = await _historyFile.readAsLines();
  }
}