import 'package:flutter/material.dart';

import 'word.dart';

class Words with ChangeNotifier {
  List<Word> freshWords = [];
  List<Word> wordsInBox = [];
  List<Word> doneWords = [];

  void fetchWords(List<String> sources, List<String> translations) {
    final titles = _getTitles();
    for (int i = 0; i < sources.length; i++) {
      if (!titles.contains(sources[i].toLowerCase().trim())) {
        freshWords.add(Word(
          title: sources[i],
          translation: translations[i],
        ));
      }
    }
    if (wordsInBox.isEmpty) {
      addEightNewWordsToBox();
    }
    notifyListeners();
  }

  void fetchPhrases(List<String> sources, List<String> urls) {
    final titles = _getTitles();
    for (int i = 0; i < sources.length; i++) {
      if (!titles.contains(sources[i].toLowerCase().trim())) {
        freshWords.add(Word(
          title: sources[i],
          url: urls[i],
        ));
      }
    }
    if (wordsInBox.isEmpty) {
      addEightNewWordsToBox();
    }
    notifyListeners();
  }

  List<String> _getTitles() {
    final totalWords = freshWords + wordsInBox;
    return totalWords.map((e) => e.title.toLowerCase().trim()).toList();
  }

  String? addEightNewWordsToBox() {
    int count = 0; // count of chosen words
    // handling words of the previous day
    for (var word in wordsInBox) {
      // fist, we should stage up all the words in box
      stageUp(word);
      // second, we choose the words we've answered wrong the day before
      if (word.answers.contains(-1)) {
        word.reset();
        // these words are already in the box but we are putting them at the first lvl
        count++;
      }
    }
    // adding fresh words to box
    int i = 0; // index of current word
    while (count < 8 && i < freshWords.length) {
      if (freshWords[i].level == 0 && freshWords[i].stage == 0) {
        freshWords[i].level = 1;
        freshWords[i].stage = 1;
        wordsInBox.add(freshWords[i]);
        freshWords.removeAt(i);
        count++;
        // now we should reset the index (i)
        i = -1;
        // we set i to -1 because it will become 0 by the line below (i++) and so we are resetting the i to 0
      }
      i++;
    }

    // in case we don't have enough fresh words
    if (count < 8) {
      return ('We don\'nt have enough fresh words to add\n(added $count word(s))');
    }
    return null;
  }

  void stageUp(Word word) {
    if (word.stage >= word.level) {
      word.level++;
      word.stage = 1;
    } else {
      word.stage++;
    }

    // finisher condition
    if (word.level == 6 && word.stage == 2) {
      // "stage == 2" means that I have answered correctly in lvl 6
      // and lvl 6 is the final lvl so we should take this word out of "Leitner" box
      word.level = 10; // lvl 10 means out of box in my app
      word.stage = 0;
      doneWords.add(word);
      wordsInBox.remove(word);
    }
  }

  List<Word> getTodayWords() {
    final List<Word> result = [];
    for (Word w in wordsInBox) {
      if (w.level > 0 && w.level < 10 && w.stage == 1) {
        result.add(w);
      }
    }
    return result;
  }
}
