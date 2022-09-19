import 'package:flutter/material.dart';

import 'word.dart';

class Words with ChangeNotifier {
  List<Word> freshWords = [];
  List<Word> freshPhrases = [];
  // we only separate words and phrases when they are fresh, in other situations they don't have any differences
  List<Word> wordsInBox = [];
  List<Word> doneWords = [];

  void fetchWords(List<String> sources, List<String> translations) {
    final titles = _getTitles(isPhrase: false);
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
    final titles = _getTitles(isPhrase: true);
    for (int i = 0; i < sources.length; i++) {
      if (!titles.contains(sources[i].toLowerCase().trim())) {
        freshPhrases.add(Word(
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

  List<String> _getTitles({required bool isPhrase}) {
    late final List<Word> totalWords;
    if (isPhrase) {
      totalWords = freshPhrases + wordsInBox;
      // "wordsInBox" contains both phrases and words but it doesn't matter
    } else {
      totalWords = freshWords + wordsInBox;
    }
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
    // we are going to add 1 phrase and 7 words to the box
    // adding fresh phrases to box
    int i = 0; // index of current word
    while (count < 1 && i < freshPhrases.length) {
      if (freshPhrases[i].level == 0 && freshPhrases[i].stage == 0) {
        freshPhrases[i].level = 1;
        freshPhrases[i].stage = 1;
        wordsInBox.add(freshPhrases[i]);
        freshPhrases.removeAt(i);
        count++;
        // now we should reset the index (i)
        i = -1;
        // we set i to -1 because it will become 0 by the line below (i++) and so we are resetting the i to 0
      }
      i++;
    }
    // adding fresh words to box
    int j = 0; // index of current word
    while (count < 8 && j < freshWords.length) {
      if (freshWords[j].level == 0 && freshWords[j].stage == 0) {
        freshWords[j].level = 1;
        freshWords[j].stage = 1;
        wordsInBox.add(freshWords[j]);
        freshWords.removeAt(j);
        count++;
        // now we should reset the index (j)
        j = -1;
        // we set i to -1 because it will become 0 by the line below (j++) and so we are resetting the i to 0
      }
      j++;
    }

    // in case we don't have enough fresh words
    if (count < 8) {
      return ('We don\'nt have enough fresh words to add\nadded $count word(s)');
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
