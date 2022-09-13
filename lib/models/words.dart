import 'package:flutter/material.dart';

import 'word.dart';

class Words with ChangeNotifier {
  List<Word> words = [];

  void fetchWords(List<String> sources, List<String> translations) {
    final titles = getTitles();
    for (int i = 0; i < sources.length; i++) {
      if (!titles.contains(sources[i].toLowerCase().trim())) {
        words.add(Word(
          title: sources[i],
          translation: translations[i],
        ));
      }
    }
    notifyListeners();
  }

  void fetchPhrases(List<String> sources, List<String> urls) {
    final titles = getTitles();
    for (int i = 0; i < sources.length; i++) {
      if (!titles.contains(sources[i].toLowerCase().trim())) {
        words.add(Word(
          title: sources[i],
          url: urls[i],
        ));
      }
    }
    notifyListeners();
  }

  List<String> getTitles() {
    return words.map((e) => e.title.toLowerCase().trim()).toList();
  }
}
