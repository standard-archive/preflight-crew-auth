import "package:flutter/material.dart";
import "package:firebase_auth/firebase_auth.dart";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _crewController = TextEditingController();
  String? _joinedCrew;
  bool _isJoining = false;

  @override
  void dispose() {
    _crewController.dispose();
    super.dispose();
  }

  void _joinCrew() {
    if (_crewController.text.trim().isEmpty) return;
    setState(() {
      _isJoining = true;
    });
    // Placeholder: actual crew-sync logic (Firestore, shared stats) is
    // out of scope for this Auth-focused elective. This demonstrates
    // the intended real-world hook without building the full feature.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _joinedCrew = _crewController.text.trim();
        _isJoining = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Joined crew '$_joinedCrew'!")),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final joinDate = user?.metadata.creationTime;

    return Scaffold(
      appBar: AppBar(
        title: const Text("PreFlight Crew"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Log out",
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.person, size: 40),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.email ?? "Unknown",
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                if (joinDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Member since ${joinDate.day}/${joinDate.month}/${joinDate.year}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                if (_joinedCrew != null) ...[
                  Icon(Icons.groups,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    "You're in crew: $_joinedCrew",
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Crew accountability features (shared streaks, nudges) are coming soon.",
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Text(
                    "Join a crew",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Team up with other students to keep each other accountable.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _crewController,
                    decoration: const InputDecoration(
                      labelText: "Crew name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _isJoining ? null : _joinCrew,
                    child: _isJoining
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Join Crew"),
                  ),
                ],
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text("Log Out"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
