import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pdict/models/words.dart';
import 'package:pdict/auth_screen.dart';
import 'package:pdict/home_page.dart';

Future<void> main() async {
  await SentryFlutter.init((options) {
    options.dsn =
        'https://daf45599389d22ee512625ad1a23491c@o4507628929220608.ingest.de.sentry.io/4507628932628560';
    // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
    // We recommend adjusting this value in production.
    options.tracesSampleRate = 1.0;
    // The sampling rate for profiling is relative to tracesSampleRate
    // Setting to 1.0 will profile 100% of sampled transactions:
    options.profilesSampleRate = 1.0;
  }, appRunner: () {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(MyApp());
  });
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
              return StreamBuilder(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (ctx, userSnapshot) {
                  if (userSnapshot.hasData) {
                    return const MyHomePage();
                  }
                  return AuthScreen();
                },
              );
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
