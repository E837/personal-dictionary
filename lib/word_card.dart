import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import 'package:pdict/models/word.dart';

class WordCard extends StatefulWidget {
  final int index;
  final bool isFocused;
  const WordCard({
    Key? key,
    required this.index,
    required this.isFocused,
  }) : super(key: key);

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> {
  bool _showTranslation = false;
  bool _isLoading = false;

  List<Widget> showTranslation(Word word, bool show) {
    if (!show) {
      return [];
    }
    return [
      // const SizedBox(height: 20),
      // Text('Description: ${widget.word.url}'),
      const SizedBox(height: 20),
      const AutoSizeText(
        'ترجمه فارسی',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 30,
        ),
        minFontSize: 20,
        maxFontSize: 30,
        maxLines: 1,
      ),
      AutoSizeText(
        word.translation ?? 'no translation available for this one',
        style: const TextStyle(fontSize: 30),
        maxLines: 3,
        textAlign: TextAlign.center,
        minFontSize: 14,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final word = Provider.of<Word>(context);

    bool isAnswered() {
      if (word.answers.contains(word.level) || word.answers.contains(-1)) {
        return true;
      }
      return false;
    }

    Color? setButtonColor() {
      if (word.answers.contains(word.level)) {
        return Colors.green[600];
      } else if (word.answers.contains(-1)) {
        return Colors.red[600];
      } else {
        return null;
      }
    }

    Color? setCardColor() {
      if (word.answers.contains(word.level)) {
        return Colors.green[100];
      } else if (word.answers.contains(-1)) {
        return Colors.red[100];
      } else if (widget.isFocused) {
        return (Theme.of(context).colorScheme.primary as MaterialColor).shade50;
      } else {
        return null;
      }
    }

    return Card(
      color: setCardColor(),
      margin: const EdgeInsets.symmetric(horizontal: 14.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          width: 280,
          height: deviceSize.height * 0.6,
          child: Column(
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        word.type == WType.word
                            ? 'Word ${widget.index + 1}'
                            : 'Phrase ${widget.index + 1}',
                        style: Theme.of(context).textTheme.headline5,
                      ),
                      Text('Level ${word.level}'),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.star_outline),
                  )
                ],
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AutoSizeText(
                      word.title,
                      style: const TextStyle(fontSize: 35),
                      minFontSize: 14,
                      maxFontSize: 35,
                      maxLines: 3,
                      wrapWords: false,
                      textAlign: TextAlign.center,
                    ),
                    ...showTranslation(word, _showTranslation),
                  ],
                ),
              ),
              // const Spacer(),
              if (!_showTranslation && word.type == WType.word)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showTranslation = true;
                    });
                  },
                  icon: const Icon(Icons.translate),
                  label: const Text('See Translation'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    primary: setButtonColor(),
                  ),
                ),
              if (_showTranslation || word.type == WType.phrase)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isAnswered() || _isLoading
                            ? null
                            : () async {
                                setState(() {
                                  _isLoading = true;
                                });
                                await word.submitAnswer(isCorrect: false);
                                setState(() {
                                  _isLoading = false;
                                });
                              },
                        icon: const Icon(Icons.warning_amber),
                        label: const Text('Wrong'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          primary: Colors.red[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isAnswered() || _isLoading
                            ? null
                            : () async {
                                setState(() {
                                  _isLoading = true;
                                });
                                await word.submitAnswer(isCorrect: true);
                                setState(() {
                                  _isLoading = false;
                                });
                              },
                        icon: const Icon(Icons.task_alt),
                        label: const Text('Correct'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          primary: Colors.green[600],
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(word.url);
                  launchUrl(uri);
                },
                icon: const Icon(Icons.search),
                label: const Text('Search Online'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
