import 'dart:io';
import 'dart:typed_data';
// import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' show Document;
import 'package:html/parser.dart' show parse;
import 'package:provider/provider.dart';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdict/models/word.dart';
import 'package:pdict/models/words.dart';
import 'package:scroll_snap_list/scroll_snap_list.dart';
import 'package:file_picker/file_picker.dart';

import 'package:pdict/word_card.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => Words(),
      child: MaterialApp(
        title: 'PersonalDict',
        theme: ThemeData(
          primarySwatch: Colors.purple,
          fontFamily: GoogleFonts.ubuntu().fontFamily,
        ),
        home: const MyHomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _focusedIndex = 0;
  // todo: dayNo should be saved on a db
  int _dayNo = 1;

  Future<void> getFile(
      {required Words wordsData, required bool isTable}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [isTable ? 'xlsx' : 'html'],
    );

    if (result != null && result.files.isNotEmpty) {
      late File file;
      if (!kIsWeb) {
        file = File(result.files.single.path!);
      }
      if (isTable) {
        // xlsx file
        late Uint8List bytes;
        if (kIsWeb) {
          bytes = result.files.single.bytes!;
        } else {
          bytes = file.readAsBytesSync();
        }
        var excel = Excel.decodeBytes(bytes);
        debugPrint('--------------');
        var sheet = excel.tables['Saved translations'];
        // "Saved translations" is the sheet name
        final List<String> sources = [];
        final List<String> translations = [];
        for (var row in sheet?.rows ?? []) {
          sources.add((row[2] as Data).value);
          translations.add((row[3] as Data).value);
        }
        wordsData.fetchWords(sources, translations);
      } else {
        // html file
        late final Document document;
        if (kIsWeb) {
          document = parse(String.fromCharCodes(result.files.single.bytes!));
        } else {
          document = parse(file.readAsStringSync());
        }
        final elements = document.querySelectorAll('a[href *="+meaning"]');
        // in every phrase I've searched on Google, I've added "meaning" at the end of the search
        final List<String> sources = [];
        final List<String> urls = [];
        for (var e in elements) {
          sources.add(Word.getPhraseTitle(e.text));
          urls.add(e.attributes['href'] ?? '');
        }
        wordsData.fetchPhrases(sources, urls);
      }
    } else {
      // User canceled the picker
    }
  }

  @override
  Widget build(BuildContext context) {
    // final deviceSize = MediaQuery.of(context).size;
    final wordsData = Provider.of<Words>(context);
    final todayWords = wordsData.getTodayWords();

    bool allAnswered() {
      for (var word in todayWords) {
        if (!(word.answers.contains(word.level) || word.answers.contains(-1))) {
          // if we are here, so we have not answered a word (at least)
          return false;
        }
      }
      return true;
    }

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
              getFile(wordsData: wordsData, isTable: false);
            },
            icon: const Icon(Icons.code),
            tooltip: 'Import .html',
          ),
          IconButton(
            onPressed: () {
              getFile(wordsData: wordsData, isTable: true);
            },
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Import .xlsx',
          ),
        ],
        leading: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.ios_share),
          tooltip: 'Export .json',
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'Day #$_dayNo',
                style: Theme.of(context).textTheme.headline4,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: todayWords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'It\'s quiet here',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 30),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'no words, no phrases,\nand nothing else...',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  )
                : ScrollSnapList(
                    itemCount: todayWords.length,
                    itemBuilder: (context, index) {
                      return ChangeNotifierProvider.value(
                        value: todayWords[index],
                        child: WordCard(
                          index: index,
                          isFocused: _focusedIndex == index,
                        ),
                      );
                    },
                    scrollDirection: Axis.horizontal,
                    onItemFocus: (index) {
                      setState(() {
                        _focusedIndex = index;
                      });
                    },
                    // todo: this 348 is strictly related to card size in "word_card.dart" and we should find a way to make it responsive (not hardcoded size)
                    itemSize: 348,
                    scrollPhysics: const BouncingScrollPhysics(),
                    // dynamicItemSize: true,
                    // dynamicSizeEquation: (difference) {
                    //   return 1 - min(difference.abs() / 900, 0.1);
                    // },
                    duration: 100,
                    curve: Curves.ease,
                  ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      'Remaining Words: ${wordsData.freshWords.length}\nRemaining Phrases: ?'),
                  Text('Today\'s words: ${todayWords.length}'),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: ElevatedButton(
              onPressed: allAnswered() && todayWords.isNotEmpty
                  ? () {
                      setState(() {
                        wordsData.addEightNewWordsToBox();
                        wordsData.getTodayWords();
                        _dayNo++;
                      });
                    }
                  : null,
              child: const Text('Next Day'),
            ),
          ),
        ],
      ),
    );
  }
}
