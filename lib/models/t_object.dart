class TObject {
  // "translation object" it means (it's the base class for GLink and Word)
  final String title;
  int _views = 0;
  bool _isFavorite = false;

  TObject({
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
