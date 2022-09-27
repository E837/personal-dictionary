import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' show Document;
import 'package:html/parser.dart' show parse;
import 'package:pdict/next_day_button.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';

import 'package:pdict/models/word.dart';
import 'package:pdict/cards_list.dart';
import 'package:pdict/models/words.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  final Future<FirebaseApp> _fbApp = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => Words()),
      ],
      child: MaterialApp(
        title: 'PersonalDict',
        theme: ThemeData(
          primarySwatch: Colors.purple,
          fontFamily: GoogleFonts.ubuntu().fontFamily,
        ),
        home: FutureBuilder(
          future: _fbApp,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrint('You have an error! ${snapshot.error.toString()}');
              return const Center(
                child: Text(
                  'Something went wrong initializing the Firebase core service',
                ),
              );
            } else if (snapshot.hasData) {
              return const MyHomePage();
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({Key? key}) : super(key: key);

  Future<void> pickFile(
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
        var sheet = excel.tables['Saved translations'];
        // "Saved translations" is the sheet name
        final List<String> sources = [];
        final List<String> translations = [];
        for (var row in sheet?.rows ?? []) {
          sources.add((row[2] as Data).value);
          translations.add((row[3] as Data).value);
        }
        await wordsData.parseNewWordsAndSendToFirestore(sources, translations);
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
        await wordsData.parseNewPhrasesAndSendToFirestore(sources, urls);
      }
    } else {
      // User canceled the picker
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('building home page');
    // final deviceSize = MediaQuery.of(context).size;
    final wordsData = Provider.of<Words>(context, listen: false);
    wordsData.fetchMetaData();
    // final metadata = Provider.of<Metadata>(context);

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
              pickFile(wordsData: wordsData, isTable: true);
            },
            icon: const Icon(Icons.playlist_add),
            tooltip: 'Import .xlsx',
          ),
        ],
        // for now we don't have any export functionality so I placed remaining buttons at left and right corners
        leading: IconButton(
          onPressed: () {
            pickFile(wordsData: wordsData, isTable: false);
          },
          icon: const Icon(Icons.code),
          tooltip: 'Import .html',
        ),
        // leading: IconButton(
        //   onPressed: () {},
        //   icon: const Icon(Icons.ios_share),
        //   tooltip: 'Export .json',
        // ),
      ),
      body: Consumer<Words>(
        builder: (context, data, child) {
          return Column(
            children: [
              Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    'Day #${data.fbDayNo}',
                    style: Theme.of(context).textTheme.headline4,
                  ),
                ),
              ),
              child!, // child is the CardsList widget
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          'Remaining Words: ${data.fbFreshWordsLength}\nRemaining Phrases: ${data.fbFreshPhrasesLength}'),
                      Text(
                          'Today\'s words: ${data.getWordsToReadFromWordsInBox().length}\n WordsInBox: ${data.wordsInBox.length}'),
                    ],
                  ),
                ),
              ),
              // the NextDayButton widget has the "const" so it won't rebuild from here, it has it's own listener inside (and it's good)
              const NextDayButton(),
            ],
          );
        },
        child: const Expanded(
          flex: 5,
          child: CardsList(),
        ),
      ),
    );
  }
}
