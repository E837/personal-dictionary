import 'package:pdict/models/t_object.dart';

class Word extends TObject {
  final String description;
  final String translation;

  Word({
    required String title,
    required this.description,
    required this.translation,
  }) : super(title: title);
}
