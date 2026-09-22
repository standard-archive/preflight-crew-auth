import "package:flutter/material.dart";
import "package:firebase_core/firebase_core.dart";
import "package:google_fonts/google_fonts.dart";
import "firebase_options.dart";
import "src/screens/auth_gate.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PreFlightCrewApp());
}

class PreFlightCrewApp extends StatelessWidget {
  const PreFlightCrewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "PreFlight Crew",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.deepPurpleAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurpleAccent,
          surface: Color(0xFF1E1E1E),
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      ),
      home: const AuthGate(),
    );
  }
}
