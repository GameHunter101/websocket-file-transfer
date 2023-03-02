import 'package:flutter/material.dart';
import 'package:websocket_client/history.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({
    super.key,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final History history;

  @override
  void initState() {
    super.initState();
    history = History();
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var headerStyle = theme.textTheme.displayMedium!
        .copyWith(color: theme.colorScheme.onPrimaryContainer);
    return Builder(builder: (context) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              "History",
              style: headerStyle,
            ),
          ),
          Expanded(
            child: RawScrollbar(
              thumbColor: theme.colorScheme.secondary,
              radius: Radius.circular(20),
              thickness: 5,
              child: history.parsedFile.length > 0
                  ? ListView.builder(
                      itemCount: history.parsedFile.length,
                      itemBuilder: (context, i) {
                        return ListTile(
                          leading: Icon(
                              history.parsedFile[i].contains("file") == 0
                                  ? Icons.insert_drive_file_outlined
                                  : Icons.textsms_outlined),
                          title: Text(history.parsedFile[i]),
                        );
                      },
                    )
                  : Text("no history"),
            ),
          ),
        ],
      );
    });
  }
}
/* Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("History", style: headerStyle),
          ),
          ListView(
            children: [
              for (var i = 0; i < 500; i++)
              ListTile(
                leading: Icon(i%2==0?Icons.insert_drive_file_outlined:Icons.textsms_outlined),
                title: Text(i%2==0?"file":"text"),
              )
            ],
          ),
          ElevatedButton(
              onPressed: () async {
                final path = (await getApplicationSupportDirectory()).path;
                File file = File("$path/history.json");
                file.delete();
                //   print("${await file.exists()}, ${file.path}");
              },
              child: Text("stuff"))
        ],
      ));
    }); */