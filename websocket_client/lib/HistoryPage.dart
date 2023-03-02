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
  final _history = History();
  int _length = 0;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      _length = (await _history.readFile()).length;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var headerStyle = theme.textTheme.displayMedium!
        .copyWith(color: theme.colorScheme.onPrimaryContainer);
    return FutureBuilder(
      future: _history.readFile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  "History",
                  style: headerStyle,
                ),
              ),
              snapshot.data!.length > 0
                  ? Expanded(
                      child: RawScrollbar(
                        thumbColor: theme.colorScheme.secondary,
                        radius: Radius.circular(20),
                        thickness: 5,
                        controller: _scrollController,
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context)
                              .copyWith(scrollbars: false),
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, i) {
                              return ListTile(
                                leading: Icon(
                                    snapshot.data![i].contains("file") == 0
                                        ? Icons.insert_drive_file_outlined
                                        : Icons.textsms_outlined),
                                title: Text(snapshot.data![i]),
                              );
                            },
                          ),
                        ),
                      ),
                    )
                  : Text("No history"),
              if (snapshot.data!.length > 0)
                Padding(
                  padding: const EdgeInsets.only(
                      bottom: 20, left: 10, right: 10, top: 10),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _history.clearFile();
                      setState(() {
                        _length = 0;
                      });
                    },
                    icon: Icon(Icons.delete_outline),
                    label: Text("Clear History"),
                  ),
                ),
            ],
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
