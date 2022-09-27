import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pdict/models/words.dart';

class NextDayButton extends StatefulWidget {
  const NextDayButton({Key? key}) : super(key: key);

  @override
  State<NextDayButton> createState() => _NextDayButtonState();
}

class _NextDayButtonState extends State<NextDayButton> {
  @override
  Widget build(BuildContext context) {
    final wordsData = Provider.of<Words>(context);

    bool allAnswered() {
      for (var word in wordsData.wordsInBox) {
        if (!(word.answers.contains(word.level) || word.answers.contains(-1))) {
          // if we are here, so we have not answered a word (at least)
          return false;
        }
      }
      return true;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onLongPress: () {
            setState(() {});
          },
          child: Container(
            width: double.infinity,
            height: 60,
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
        ElevatedButton(
          onPressed: allAnswered()
              ? () async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final response = await wordsData.makeNewDay();
                  scaffoldMessenger.showSnackBar(SnackBar(
                      content: Text(
                    response ?? 'Now you can restart the app',
                    // if "response != null" means we've got an error (it returns the error msg)
                    textAlign: TextAlign.center,
                  )));
                }
              : null,
          style: ElevatedButton.styleFrom(
            fixedSize: const Size(320, 60),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
          ),
          child: const Text('NEXT DAY'),
        ),
      ],
    );
  }
}
