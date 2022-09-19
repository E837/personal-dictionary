import 'package:flutter/material.dart';

enum WType {
  word,
  phrase, // refers to phrases/words I search on Google
}

class Word with ChangeNotifier {
  final String title;
  late String url;
  final String? translation;
  late final WType type;
  int level = 0;
  int stage = 0;
  int _views = 0;
  bool _isFavorite = false;
  final List<int> _answers = [];
  // the list above will keep the levels which we have answered this word's card
  // and this list will get empty if our answer (translation) is wrong

  Word({
    required this.title,
    String? url,
    this.translation,
  }) {
    this.url = url ?? makeUrl(title);
    type = resolveType(this.url);
  }

  int get views => _views;

  bool get isFavorite => _isFavorite;

  List<int> get answers => List.unmodifiable(_answers);

  void submitCorrectAnswer() {
    _answers.add(level);
    notifyListeners();
  }

  void submitWrongAnswer() {
    _answers.add(-1);
    // by adding -1 we are setting a flag to tell that we have answered this one wrong
    notifyListeners();
  }

  void reset() {
    level = 1;
    stage = 1;
    _answers.clear();
  }

  void addView() {
    _views++;
  }

  void toggleFavorite() {
    _isFavorite = !_isFavorite;
  }

  static String makeUrl(String title) {
    final titleWithoutSpaces = title.replaceAll(' ', '%20');
    return 'https://translate.google.com/?source=osdd&sl=auto&tl=fa&text=$titleWithoutSpaces&op=translate';
  }

  static WType resolveType(String url) {
    if (url.contains('translate.google.com')) {
      return WType.word;
    } else {
      return WType.phrase;
    }
  }

  static String getPhraseTitle(String messyTitle) {
    return messyTitle.replaceFirst('meaning - Google Search', '').trim();
  }
}
