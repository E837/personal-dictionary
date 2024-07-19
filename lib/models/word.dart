import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

enum WType {
  word,
  phrase, // refers to phrases/words I search on Google
}

WType parseToWType(String typeName) {
  if (typeName == 'word') {
    return WType.word;
  } else if (typeName == 'phrase') {
    return WType.phrase;
  } else {
    debugPrint('weird state while parsing the word type');
    return WType.word;
  }
}

class Word with ChangeNotifier {
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  final String id;
  final String title;
  late String url;
  final String? translation;
  late final WType type;
  int level = 0;
  int stage = 0;
  int views = 0;
  bool isFavorite = false;
  final List<int> _answers = [];
  // the list above will keep the levels which we have answered this word's card
  // and this list will get empty if our answer (translation) is wrong

  Word({
    required this.id,
    required this.title,
    String? url,
    this.translation,
  }) {
    this.url = url ?? makeUrl(title);
    type = resolveType(this.url);
  }

  List<int> get answers => List.unmodifiable(_answers);

  void setAnswers(List<int> answers) {
    _answers.clear();
    for (int ans in answers) {
      _answers.add(ans);
    }
  }

  Future<void> submitAnswer({required bool isCorrect}) async {
    if (isCorrect) {
      // answer is correct
      _answers.add(level);
    } else {
      // answer is wrong
      _answers.add(-1);
      // by adding -1 we are setting a flag to tell that we have answered this one wrong
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wordsInBox')
        .doc(id)
        .update({'answers': _answers}).catchError((error) async{
      debugPrint('submitting answer failed\nError: $error');
      _answers.remove(isCorrect ? level : -1);
      await Sentry.captureException(
        error,
        stackTrace: StackTrace,
      );
    });
    notifyListeners();
  }

  Future<void> reset() async {
    debugPrint('inside reset');
    final oldLevel = level;
    final oldStage = stage;
    final oldAnswers = _answers;
    level = 1;
    stage = 1;
    _answers.clear();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('wordsInBox')
        .doc(id).update({
      'level': level,
      'stage': stage,
      'answers': _answers,
    }).catchError((error) async{
      debugPrint('resetting the word failed\nError: $error');
      level = oldLevel;
      stage = oldStage;
      setAnswers(oldAnswers);
      await Sentry.captureException(
        error,
        stackTrace: StackTrace,
      );
    });
  }

  void addView() {
    // todo: use the function and adapt it to firestore usage
    views++;
  }

  void toggleFavorite() {
    // todo: use the function and adapt it to firestore usage
    isFavorite = !isFavorite;
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

  Map<String, dynamic> get toMap => {
        'title': title,
        'url': url,
        'translation': translation,
        'type': type.name,
        'level': level,
        'stage': stage,
        'views': views,
        'isFavorite': isFavorite,
        'answers': _answers,
      };

  static Word parseMap(String id, Map<String, dynamic> data) {
    final word = Word(
      id: id,
      title: data['title'],
      url: data['url'],
      translation: data['translation'],
    );
    word.level = data['level'];
    word.stage = data['stage'];
    word.views = data['views'];
    word.isFavorite = data['isFavorite'];
    // ".cast<int>()" converts List<dynamic> to List<int>
    word.setAnswers(data['answers'].cast<int>());
    return word;
  }
}
