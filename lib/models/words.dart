import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'word.dart';

class Words with ChangeNotifier {
  List<Word> freshWords = [];
  List<Word> freshPhrases = [];
  // we only separate words and phrases when they are fresh, in other situations they don't have any differences
  List<Word> wordsInBox = [];
  List<Word> doneWords = [];

  /// ---------------------- metadata store -----------------------

  int _fbWordsLength = 0; // fb = firebase
  int _fbPhrasesLength = 0;
  int _fbFreshWordsLength = 0;
  int _fbFreshPhrasesLength = 0;
  int _fbDayNo = 0;

  int get fbWordsLength => _fbWordsLength;
  int get fbPhrasesLength => _fbPhrasesLength;
  int get fbFreshWordsLength => _fbFreshWordsLength;
  int get fbFreshPhrasesLength => _fbFreshPhrasesLength;
  int get fbDayNo => _fbDayNo;

  Future<void> fetchMetaData() async {
    bool hasError = false;

    final rawMetadata = await FirebaseFirestore.instance
        .collection('metadata')
        .get()
        .catchError((error) {
      debugPrint('error while getting metadata\nError: $error');
      hasError = true;
    });
    if (hasError) {
      return;
    }

    //converting firestore data to Map
    final Map<String, dynamic> metadata = {};
    for (var doc in rawMetadata.docs) {
      metadata[doc.id] = doc.data()['value'];
    }

    _fbFreshWordsLength = metadata['freshWordsLength'] ?? 0;
    if (metadata['freshWordsLength'] == null) {
      // initializing the freshWords length on firestore
      await FirebaseFirestore.instance
          .collection('metadata')
          .doc('freshWordsLength')
          .set({'value': 0}).catchError((error) {
        debugPrint('setting freshWords length as 0 failed\nError $error');
      });
    }

    _fbFreshPhrasesLength = metadata['freshPhrasesLength'] ?? 0;
    if (metadata['freshPhrasesLength'] == null) {
      // initializing the freshPhrases length on firestore
      await FirebaseFirestore.instance
          .collection('metadata')
          .doc('freshPhrasesLength')
          .set({'value': 0}).catchError((error) {
        debugPrint('setting freshPhrases length as 0 failed\nError $error');
      });
    }

    _fbDayNo = metadata['dayNo'] ?? 0;
    if (metadata['dayNo'] == null) {
      // initializing dayNo on firestore
      await FirebaseFirestore.instance
          .collection('metadata')
          .doc('dayNo')
          .set({'value': 0}).catchError((error) {
        debugPrint('setting dayNo as 0 failed\nError $error');
      });
    }

    _fbWordsLength = metadata['wordsLength'] ?? 0;
    _fbPhrasesLength = metadata['phrasesLength'] ?? 0;

    notifyListeners();
  }

  Future<void> dayNoUp() async {
    await FirebaseFirestore.instance
        .collection('metadata')
        .doc('dayNo')
        .update({'value': FieldValue.increment(1)}).then((_) {
      _fbDayNo++;
      notifyListeners();
    }).catchError((error) {
      debugPrint('increasing dayNo on firestore failed\nError $error');
      throw Exception('dayNo incrementation failed');
    });
  }

  /// ---------------------- end of metadata store -----------------------

  Future<void> parseNewWordsAndSendToFirestore(
      List<String> sources, List<String> translations) async {
    await fetchMetaData();
    for (int i = _fbWordsLength; i < sources.length; i++) {
      // by the line below we initialize a temp word to configure it's data structure...
      // but we won't save it's id anywhere but we keep the word with the id we get from firebase
      final wordWithTempId = Word(
        id: 'temp',
        title: sources[i],
        translation: translations[i],
      );

      await FirebaseFirestore.instance
          .collection('freshWords')
          .add(wordWithTempId.toMap)
          .then((value) async {
        debugPrint('word $i uploaded successfully -> id: ${value.id}');
        final thisWord = Word(
          id: value.id,
          title: sources[i],
          translation: translations[i],
        );
        freshWords.add(thisWord);
        await FirebaseFirestore.instance
            .collection('metadata')
            .doc('freshWordsLength')
            .update({'value': FieldValue.increment(1)})
            .then((_) => _fbFreshWordsLength++)
            .catchError((error) {
              debugPrint('increasing freshWordsLength failed\nError: $error');
            });
      }).catchError((error) {
        debugPrint('word $i failed. error: $error');
      });
    }

    if (wordsInBox.isEmpty) {
      await makeNewDay();
    }

    // sending the words length to firestore
    await FirebaseFirestore.instance
        .collection('metadata')
        .doc('wordsLength')
        .set({'value': max(_fbWordsLength, sources.length)});

    notifyListeners();
  }

  Future<void> parseNewPhrasesAndSendToFirestore(
      List<String> sources, List<String> urls) async {
    await fetchMetaData();
    for (int i = _fbPhrasesLength; i < sources.length; i++) {
      // by the line below we initialize a temp word to configure it's data structure...
      // but we won't save it's id anywhere but we keep the word with the id we get from firebase
      final wordWithTempId = Word(
        id: 'temp',
        title: sources[i],
        url: urls[i],
      );

      await FirebaseFirestore.instance
          .collection('freshPhrases')
          .add(wordWithTempId.toMap)
          .then((value) async {
        debugPrint('phrase $i uploaded successfully -> id: ${value.id}');
        final thisWord = Word(
          id: value.id,
          title: sources[i],
          url: urls[i],
        );
        freshPhrases.add(thisWord);
        await FirebaseFirestore.instance
            .collection('metadata')
            .doc('freshPhrasesLength')
            .update({'value': FieldValue.increment(1)})
            .then((_) => _fbFreshPhrasesLength++)
            .catchError((error) {
              debugPrint('increasing freshPhrasesLength failed\nError: $error');
            });
      }).catchError((error) {
        debugPrint('phrase $i failed. error: $error');
      });
    }

    if (wordsInBox.isEmpty) {
      await makeNewDay();
    }

    // sending the words length to firestore
    await FirebaseFirestore.instance
        .collection('metadata')
        .doc('phrasesLength')
        .set({'value': max(_fbPhrasesLength, sources.length)});

    notifyListeners();
  }

  Future<String?> makeNewDay({int wCount = 8}) async {
    // wCount is the count of words the user (me) wants to learn
    // increasing the dayNo on firestore
    try {
      await dayNoUp();
    } catch (error) {
      // if dayNo increment fails, we return and don't let the method to continue it's job
      return (error.toString());
    }

    int count = 0; // count of chosen words

    // handling words of the previous day
    bool phraseAnsweredWrong = false;
    for (var word in wordsInBox) {
      // fist, we should stage up all the words in box
      await stageUp(word);
      // second, we choose the words we've answered wrong the day before
      if (word.answers.contains(-1)) {
        await word.reset();
        // these words are already in the box but we are putting them at the first lvl
        count++;
        if (word.type == WType.phrase) {
          phraseAnsweredWrong = true;
        }
      }
    }

    // we are going to add 1 phrase and 7 words to the box
    /// --------- adding fresh phrases to box ---------
    int needCount = 1;
    if (!phraseAnsweredWrong) {
      // if we have answered the phrase of yesterday correctly, so we can add another one...
      // otherwise, we should learn the previous one first
      final freshPhrasesData = await FirebaseFirestore.instance
          .collection('freshPhrases')
          .limit(needCount)
          .get()
          .catchError((error) {
        debugPrint(
            'fetching freshPhrases from firestore failed\nError: $error');
      });
      freshPhrases = freshPhrasesData.docs
          .map((w) => Word.parseMap(w.id, w.data()))
          .toList();

      if (freshPhrases.isNotEmpty) {
        // decreasing the freshPhrasesLength
        // we don't need to wait for this to happen, because we don't need the info right now
        FirebaseFirestore.instance
            .collection('metadata')
            .doc('freshPhrasesLength')
            .update({'value': FieldValue.increment(-needCount)})
            // by setting "-needCount" (the "-" is important) we are indeed decreasing the freshPhrasesLength
            .then((_) => _fbFreshPhrasesLength--)
            .catchError((error) {
              debugPrint('decreasing freshPhrasesLength failed\nError: $error');
            });
      }

      final freshPhrasesCopy = List.of(freshPhrases);
      for (var word in freshPhrasesCopy) {
        if (word.level == 0 && word.stage == 0) {
          word.level = 1;
          word.stage = 1;
          await FirebaseFirestore.instance
              .collection('wordsInBox')
              .doc(word.id)
              .set(word.toMap)
              .then((value) {
            debugPrint('added phrase "${word.title}" to the box successfully');
            wordsInBox.add(word);
          }).catchError((error) {
            debugPrint('adding phrase "${word.title}" to the box failed');
          });
          await FirebaseFirestore.instance
              .collection('freshPhrases')
              .doc(word.id)
              .delete()
              .then((value) {
            debugPrint(
                'deleted phrase "${word.title}" from the freshPhrases list');
            freshPhrases.remove(word);
          }).catchError((error) {
            debugPrint(
                'deleting phrase "${word.title}" from the freshPhrases failed');
          });
          count++;
        }
      }
    }

    /// --------- adding fresh words to box ---------
    needCount = max(wCount - count, 0);
    final freshWordsData = await FirebaseFirestore.instance
        .collection('freshWords')
        .limit(needCount)
        // for count to reach wCount (and "max" prevents negative numbers)
        .get()
        .catchError((error) {
      debugPrint('fetching freshWords from firestore failed\nError: $error');
    });
    freshWords =
        freshWordsData.docs.map((w) => Word.parseMap(w.id, w.data())).toList();

    if (freshWords.isNotEmpty) {
      // decreasing the freshWordsLength
      // we don't need to wait for this to happen, because we don't need the info right now
      FirebaseFirestore.instance
          .collection('metadata')
          .doc('freshWordsLength')
          .update({'value': FieldValue.increment(-needCount)})
          // by setting "-needCount" (the "-" is important) we are indeed decreasing the freshWordsLength
          .then((_) => _fbFreshWordsLength--)
          .catchError((error) {
            debugPrint('decreasing freshWordsLength failed\nError: $error');
          });
    }

    final freshWordsCopy = List.of(freshWords);
    for (var word in freshWordsCopy) {
      if (word.level == 0 && word.stage == 0) {
        word.level = 1;
        word.stage = 1;
        await FirebaseFirestore.instance
            .collection('wordsInBox')
            .doc(word.id)
            .set(word.toMap)
            .then((value) {
          debugPrint('added word "${word.title}" to the box successfully');
          wordsInBox.add(word);
        }).catchError((error) {
          debugPrint('adding word "${word.title}" to the box failed');
        });
        await FirebaseFirestore.instance
            .collection('freshWords')
            .doc(word.id)
            .delete()
            .then((value) {
          debugPrint('deleted word "${word.title}" from the freshWords list');
          freshWords.remove(word);
        }).catchError((error) {
          debugPrint(
              'deleting word "${word.title}" from the freshWords failed');
        });
        count++;
      }
    }

    notifyListeners();

    // in case we don't have enough fresh words
    if (count < wCount) {
      return ('We don\'nt have enough fresh words to add\nadded $count word(s)');
    }

    return null;
  }

  Future<void> stageUp(Word word) async {
    final doc =
        FirebaseFirestore.instance.collection('wordsInBox').doc(word.id);
    final oldLevel = word.level;
    final oldStage = word.stage;
    if (word.stage >= word.level) {
      word.level++;
      word.stage = 1;
    } else {
      word.stage++;
    }
    // updating firestore data
    await doc.update({
      'level': word.level,
      'stage': word.stage,
    }).catchError((error) {
      debugPrint('stageUp process failed\nError: $error');
      word.level = oldLevel;
      word.stage = oldStage;
    });

    // finisher condition
    if (word.level == 6 && word.stage == 2) {
      // "stage == 2" means that I have answered correctly in lvl 6
      // and lvl 6 is the final lvl so we should take this word out of "Leitner" box
      word.level = 10; // lvl 10 means out of box in my app
      word.stage = 0;
      doneWords.add(word);
      wordsInBox.remove(word);

      final newDoc =
          FirebaseFirestore.instance.collection('doneWords').doc(word.id);

      await newDoc.set(word.toMap).then((_) {
        // deleting existing doc from "wordsInBox"
        doc.delete().then((_) async {
          await newDoc.update({
            'level': word.level,
            'stage': word.stage,
          }).catchError((error) {
            debugPrint(
                'updating level/stage of this doneWord failed\nError: $error');
            word.level = oldLevel;
            word.stage = oldStage;
          });
        }).catchError((error) {
          debugPrint('removing item from "wordsInBox" failed\nError: $error');
          wordsInBox.add(word);
        });
      }).catchError((error) {
        debugPrint('adding item to "doneWords" failed\nError: $error');
        doneWords.remove(word);
      });
    }
  }

  Future<List<Word>> fetchBoxWords() async {
    debugPrint('============== fetching box words');
    final wordsData =
        await FirebaseFirestore.instance.collection('wordsInBox').get();
    wordsInBox = wordsData.docs.map((w) {
      return Word.parseMap(w.id, w.data());
    }).toList();
    return getWordsToReadFromWordsInBox();
  }

  List<Word> getWordsToReadFromWordsInBox() {
    final List<Word> result = [];
    for (Word w in wordsInBox) {
      if (w.level > 0 && w.level < 10 && w.stage == 1) {
        result.add(w);
      }
    }
    return result;
  }
}
