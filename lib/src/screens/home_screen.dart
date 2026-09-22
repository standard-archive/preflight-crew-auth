import "dart:convert";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:crypto/crypto.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "crew_directory_screen.dart";

String hashPassword(String password) {
  return sha256.convert(utf8.encode(password)).toString();
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _crewController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _crewController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _slugify(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }

  Future<void> _joinCrew(String rawName, String password) async {
    final name = rawName.trim();
    if (name.isEmpty || password.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final slug = _slugify(name);
    if (slug.isEmpty) return;

    setState(() => _isJoining = true);

    final crewRef = FirebaseFirestore.instance.collection('crews').doc(slug);
    final privateRef = crewRef.collection('private').doc('config');
    final memberRef = crewRef.collection('members').doc(user.uid);
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final passwordHash = hashPassword(password);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userSnap = await transaction.get(userRef);
        if (userSnap.exists && userSnap.data()?['crewId'] != null) {
          throw StateError('already-in-crew');
        }

        final crewSnap = await transaction.get(crewRef);
        final now = FieldValue.serverTimestamp();

        if (!crewSnap.exists) {
          transaction.set(crewRef, {
            'name': name,
            'createdAt': now,
            'memberCount': 1,
          });
          transaction.set(privateRef, {'passwordHash': passwordHash});
        } else {
          transaction.update(crewRef, {
            'memberCount': FieldValue.increment(1),
          });
        }

        transaction.set(memberRef, {
          'email': user.email,
          'joinedAt': now,
          'passwordHash': passwordHash,
        });

        transaction.set(
          userRef,
          {'email': user.email, 'crewId': slug},
          SetOptions(merge: true),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Joined crew '$name'!")),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = (e is StateError && e.message == 'already-in-crew')
            ? "You've already joined a crew."
            : "Couldn't join crew — check the name and password.";
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _openDirectory() async {
    final result = await Navigator.push<({String name, String password})>(
      context,
      MaterialPageRoute(builder: (_) => const CrewDirectoryScreen()),
    );
    if (result != null) {
      _joinCrew(result.name, result.password);
    }
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
                ).animate().fadeIn(duration: 600.ms).scale(
                    begin: const Offset(0.8, 0.8)),
                const SizedBox(height: 16),
                Text(
                  user?.email ?? "Unknown",
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
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
                if (user != null)
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .snapshots(),
                    builder: (context, userDocSnap) {
                      if (userDocSnap.connectionState ==
                              ConnectionState.waiting &&
                          !userDocSnap.hasData) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        );
                      }

                      final crewId =
                          userDocSnap.data?.data()?['crewId'] as String?;

                      if (crewId == null) {
                        return _JoinCrewForm(
                          nameController: _crewController,
                          passwordController: _passwordController,
                          isJoining: _isJoining,
                          onJoin: () => _joinCrew(
                              _crewController.text, _passwordController.text),
                          onBrowse: _openDirectory,
                        );
                      }

                      return StreamBuilder<
                          DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('crews')
                            .doc(crewId)
                            .snapshots(),
                        builder: (context, crewSnap) {
                          if (crewSnap.connectionState ==
                                  ConnectionState.waiting &&
                              !crewSnap.hasData) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!crewSnap.hasData || !crewSnap.data!.exists) {
                            return _JoinCrewForm(
                              nameController: _crewController,
                              passwordController: _passwordController,
                              isJoining: _isJoining,
                              onJoin: () => _joinCrew(_crewController.text,
                                  _passwordController.text),
                              onBrowse: _openDirectory,
                            );
                          }

                          final crewData = crewSnap.data!.data()!;
                          final crewName =
                              crewData['name'] as String? ?? crewId;

                          return StreamBuilder<
                              QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('crews')
                                .doc(crewId)
                                .collection('members')
                                .orderBy('joinedAt')
                                .snapshots(),
                            builder: (context, membersSnap) {
                              final members = (membersSnap.data?.docs ?? [])
                                  .map((d) => (
                                        email: d.data()['email'] as String? ??
                                            'Unknown',
                                        joinedAt:
                                            (d.data()['joinedAt']
                                                    as Timestamp?)
                                                ?.toDate(),
                                      ))
                                  .toList();

                              return _CrewDetails(
                                  crewName: crewName, members: members);
                            },
                          );
                        },
                      );
                    },
                  ),
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

class _JoinCrewForm extends StatelessWidget {
  const _JoinCrewForm({
    required this.nameController,
    required this.passwordController,
    required this.isJoining,
    required this.onJoin,
    required this.onBrowse,
  });

  final TextEditingController nameController;
  final TextEditingController passwordController;
  final bool isJoining;
  final VoidCallback onJoin;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Join a crew",
          style: Theme.of(context).textTheme.titleMedium,
        ).animate().fadeIn(duration: 500.ms),
        const SizedBox(height: 8),
        const Text(
          "Team up with other students to keep each other accountable.",
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: onBrowse,
          icon: const Icon(Icons.groups_outlined),
          label: const Text("Browse existing crews"),
        ),
        const SizedBox(height: 16),
        const Text("or create a new one"),
        const SizedBox(height: 16),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: "Crew name",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Crew password",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: isJoining ? null : onJoin,
          child: isJoining
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Create / Join Crew"),
        ),
      ],
    );
  }
}

class _CrewDetails extends StatelessWidget {
  const _CrewDetails({required this.crewName, required this.members});

  final String crewName;
  final List<({String email, DateTime? joinedAt})> members;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.groups,
                size: 48, color: Theme.of(context).colorScheme.primary)
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(begin: const Offset(0.8, 0.8)),
        const SizedBox(height: 12),
        Text(
          "You're in crew: $crewName",
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
        const SizedBox(height: 16),
        Text(
          "Members (${members.length})",
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        ...members.map(
          (m) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    m.joinedAt != null
                        ? "${m.email} · joined ${m.joinedAt!.day}/${m.joinedAt!.month}/${m.joinedAt!.year}"
                        : m.email,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
