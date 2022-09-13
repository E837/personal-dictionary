enum WType {
  word,
  phrase, // refers to phrases/words I search on Google
}

class Word {
  final String title;
  late String url;
  final String? translation;
  late final WType type;
  int level = 1;
  int stage = 1;
  int _views = 0;
  bool _isFavorite = false;

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

  void stageUp() {
    if (stage >= level) {
      level++;
      stage = 1;
    } else {
      stage++;
    }

    // finisher condition
    if (level == 6 && stage == 2) {
      // "stage == 2" means that I have answered correctly in lvl 6
      // and lvl 6 is the final lvl so we should take this word out of "Leitner" box
      level = 10; // lvl 10 means out of box in my app
      stage = 1;
    }
  }
}
