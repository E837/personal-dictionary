import 'package:pdict/models/t_object.dart';

class GLink extends TObject {
  String url;

  GLink({
    required String title,
    required this.url,
  }) : super(title: title);
}
