import "package:flutter/material.dart";
import "package:firebase_auth/firebase_auth.dart";

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text("PreFlight Crew")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Signed in as: ${user?.email ?? "unknown"}"),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              child: const Text("Log Out"),
            ),
          ],
        ),
      ),
    );
  }
}
