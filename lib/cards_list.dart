import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scroll_snap_list/scroll_snap_list.dart';

import 'package:pdict/word_card.dart';
import 'models/word.dart';
import 'models/words.dart';

class CardsList extends StatelessWidget {
  // final List<Word> todayWords;
  const CardsList({
    Key? key,
    // required this.todayWords,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('building cards');
    return FutureBuilder<List<Word>>(
      future: Provider.of<Words>(context).fetchBoxWords(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(snapshot.error.toString());
          return Center(
            child: Text(
              'Something went wrong while loading the box words\nError: ${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        } else if (snapshot.hasData) {
          final List<Word> todayWords = snapshot.data!;

          return todayWords.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'It\'s quiet here',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 30),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'no words, no phrases,\nand nothing else...',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20),
                      ),
                    ],
                  ),
                )
              : ActualCards(todayWords: todayWords);
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}

class ActualCards extends StatefulWidget {
  final List<Word> todayWords;
  const ActualCards({
    Key? key,
    required this.todayWords,
  }) : super(key: key);

  @override
  State<ActualCards> createState() => _ActualCardsState();
}

class _ActualCardsState extends State<ActualCards> {
  int _focusedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return ScrollSnapList(
      itemCount: widget.todayWords.length,
      itemBuilder: (context, index) {
        return ChangeNotifierProvider.value(
          value: widget.todayWords[index],
          child: WordCard(
            index: index,
            isFocused: _focusedIndex == index,
          ),
        );
      },
      scrollDirection: Axis.horizontal,
      onItemFocus: (index) {
        setState(() {
          _focusedIndex = index;
        });
      },
      // todo: this 348 is strictly related to card size in "word_card.dart" and we should find a way to make it responsive (not hardcoded size)
      itemSize: 348,
      scrollPhysics: const BouncingScrollPhysics(),
      // dynamicItemSize: true,
      // dynamicSizeEquation: (difference) {
      //   return 1 - min(difference.abs() / 900, 0.1);
      // },
      duration: 100,
      curve: Curves.ease,
    );
  }
}
