import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pdict/models/word.dart';

class WordCard extends StatefulWidget {
  final int index;
  final Word word;
  final bool isFocused;
  const WordCard({
    Key? key,
    required this.index,
    required this.word,
    required this.isFocused,
  }) : super(key: key);

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> {
  bool _showTranslation = false;

  List<Widget> showTranslation(bool show) {
    if (!show) {
      return [];
    }
    return [
      // const SizedBox(height: 20),
      // Text('Description: ${widget.word.url}'),
      const SizedBox(height: 20),
      const Text(
        'ترجمه فارسی',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 30,
        ),
      ),
      AutoSizeText(
        widget.word.translation ?? 'no translation available for this one',
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
    return Card(
      color: widget.isFocused
          ? (Theme.of(context).colorScheme.primary as MaterialColor).shade50
          : null,
      margin: const EdgeInsets.symmetric(horizontal: 14.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          width: deviceSize.width * 0.7,
          height: deviceSize.height * 0.6,
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    widget.word.type == WType.word
                        ? 'Word ${widget.index + 1}'
                        : 'Phrase ${widget.index + 1}',
                    style: Theme.of(context).textTheme.headline5,
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
                      widget.word.title,
                      style: const TextStyle(fontSize: 35),
                      minFontSize: 14,
                      maxFontSize: 35,
                      maxLines: 3,
                      wrapWords: false,
                      textAlign: TextAlign.center,
                    ),
                    ...showTranslation(_showTranslation),
                  ],
                ),
              ),
              // const Spacer(),
              if (!_showTranslation && widget.word.type == WType.word)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showTranslation = true;
                    });
                  },
                  icon: const Icon(Icons.translate),
                  label: const Text('See Translation'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              if (_showTranslation || widget.word.type == WType.phrase)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.warning_amber),
                        label: const Text('Wrong'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.red[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.task_alt),
                        label: const Text('Correct'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.green[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(widget.word.url);
                  launchUrl(uri);
                },
                icon: const Icon(Icons.search),
                label: const Text('Search Online'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
