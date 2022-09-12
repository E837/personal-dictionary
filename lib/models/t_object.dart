class Translate {
  final String title;
  int _views = 0;
  bool _isFavorite = false;

  Translate({
    required this.title,
  });

  int get views => _views;

  bool get isFavorite => _isFavorite;

  void addView() {
    _views++;
  }

  void toggleFavorite() {
    _isFavorite = !_isFavorite;
  }
}
