import 'dart:io';
import 'package:html/parser.dart' show parse;

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_snap_list/scroll_snap_list.dart';
import 'package:file_picker/file_picker.dart';

import 'package:pdict/word_card.dart';
import 'temp_data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PersonalDict',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        fontFamily: GoogleFonts.ubuntu().fontFamily,
      ),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const itemsCount = 20;
  int _focusedIndex = 0;

  Future<void> getFile({required bool isTable}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [isTable ? 'xlsx' : 'html'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      if (isTable) {
        var bytes = file.readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);
        debugPrint('--------------');
        var sheet = excel.tables['Saved translations'];
        // "Saved translations" is the sheet name
        print(sheet?.maxCols);
        print(sheet?.maxRows);
        for (var row in sheet?.rows ?? []) {
          print((row[2] as Data).value); // 3rd column contains the source word
          print((row[3] as Data).value); // 4th column contains the translation
        }
      } else {
        final document = parse(file.readAsStringSync());
        final elements = document.querySelectorAll('a[href *="+meaning"]');
        // in every phrase I've searched on Google, I've added "meaning" at the end of the search
        for (var e in elements) {
          print(e.text);
        }
      }
    } else {
      // User canceled the picker
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Personal Dictionary',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              getFile(isTable: false);
            },
            icon: const Icon(Icons.code),
            tooltip: 'Import .html',
          ),
          IconButton(
            onPressed: () {
              getFile(isTable: true);
            },
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Import .csv',
          ),
        ],
        leading: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.ios_share),
          tooltip: 'Export json',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'Day #?',
                style: Theme.of(context).textTheme.headline4,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: ScrollSnapList(
              // todo: we need a way to keep items alive (or keep their state)
              // todo: card positioning has bugs (cards don't stop at center + last card buttons don't work cuz of it i think)
              itemCount: itemsCount,
              itemBuilder: (context, index) {
                return WordCard(
                  index: index,
                  word: words[index],
                  isFocused: _focusedIndex == index,
                );
              },
              onItemFocus: (index) {
                setState(() {
                  _focusedIndex = index;
                });
              },
              itemSize: deviceSize.width * 0.89,
              // scrollPhysics: const BouncingScrollPhysics(),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Remaining Words: ?\nRemaining Phrases: ?'),
                  Text('Today\'s words: $itemsCount'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
