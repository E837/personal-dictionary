import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scroll_snap_list/scroll_snap_list.dart';
import 'package:file_picker/file_picker.dart';

import 'package:pdict/word_card.dart';
import 'models/word.dart';
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
  int _focusedIndex = 0;

  Future<void> getFile({required bool isTable}) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [isTable ? 'csv' : 'html'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      print('--------------');
      print(await file.readAsString());
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
            icon: const Icon(Icons.bookmark_add),
          ),
          IconButton(
            onPressed: () {
              getFile(isTable: true);
            },
            icon: const Icon(Icons.translate),
          ),
        ],
      ),
      body: Column(
        children: [
          const Expanded(
            flex: 1,
            child: SizedBox(),
          ),
          Expanded(
            flex: 6,
            child: ScrollSnapList(
              itemCount: 10,
              itemBuilder: (context, index) {
                return WordCard(
                  word: tObjects[index] as Word,
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
                  Text('Sample text'),
                  Text('Today\'s words: 5'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
