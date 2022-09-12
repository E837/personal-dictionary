import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pdict/models/word.dart';

class WordCard extends StatefulWidget {
  final Word word;
  final bool isFocused;
  const WordCard({
    Key? key,
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
      const SizedBox(height: 20),
      Text('Description: ${widget.word.description}'),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(widget.word.translation),
          const Text(' :'),
          const Text(
            'ترجمه فارسی',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
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
        child: Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: deviceSize.width * 0.7,
            height: deviceSize.height * 0.6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.word.title,
                      style: Theme.of(context).textTheme.headline4,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.star_outline),
                    )
                  ],
                ),
                ...showTranslation(_showTranslation),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    final uri = Uri.parse(
                        'https://translate.google.com/?source=osdd&sl=auto&tl=auto&text=test&op=translate');
                    launchUrl(uri);
                  },
                  child: const Text('test'),
                ),
                if (!_showTranslation)
                  Center(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _showTranslation = true;
                        });
                      },
                      child: const Text('See Translation'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
