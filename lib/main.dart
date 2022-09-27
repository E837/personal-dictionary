import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pdict/models/words.dart';
import 'package:pdict/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  final Future<FirebaseApp> _fbApp = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => Words()),
      ],
      child: MaterialApp(
        title: 'PersonalDict',
        theme: ThemeData(
          primarySwatch: Colors.purple,
          fontFamily: GoogleFonts.ubuntu().fontFamily,
        ),
        home: FutureBuilder(
          future: _fbApp,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              debugPrint('You have an error! ${snapshot.error.toString()}');
              return const Center(
                child: Text(
                  'Something went wrong initializing the Firebase core service',
                ),
              );
            } else if (snapshot.hasData) {
              return const MyHomePage();
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
