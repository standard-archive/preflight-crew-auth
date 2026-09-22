import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _crewController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _crewController.dispose();
    super.dispose();
  }

  String _slugify(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }

  Future<void> _joinCrew() async {
    final name = _crewController.text.trim();
    if (name.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final slug = _slugify(name);
    if (slug.isEmpty) return;

    setState(() => _isJoining = true);

    final crewRef = FirebaseFirestore.instance.collection('crews').doc(slug);
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

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
            'members': {
              user.uid: {'email': user.email, 'joinedAt': now},
            },
          });
        } else {
          transaction.update(crewRef, {
            'members.${user.uid}': {'email': user.email, 'joinedAt': now},
          });
        }

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
            : "Couldn't join crew, please try again.";
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
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
                          controller: _crewController,
                          isJoining: _isJoining,
                          onJoin: _joinCrew,
                        );
                      }

                      return StreamBuilder<
                          DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('crews')
                            .doc(crewId)
                            .snapshots(),
                        builder: (context, crewSnap) {
                          if (!crewSnap.hasData || !crewSnap.data!.exists) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: CircularProgressIndicator(),
                            );
                          }

                          final crewData = crewSnap.data!.data()!;
                          final crewName = crewData['name'] as String? ?? crewId;
                          final membersMap = Map<String, dynamic>.from(
                              crewData['members'] as Map? ?? {});

                          final members = membersMap.entries.map((entry) {
                            final data =
                                Map<String, dynamic>.from(entry.value as Map);
                            final joinedAt = data['joinedAt'] as Timestamp?;
                            return (
                              email: data['email'] as String? ?? 'Unknown',
                              joinedAt: joinedAt?.toDate(),
                            );
                          }).toList()
                            ..sort((a, b) {
                              if (a.joinedAt == null || b.joinedAt == null) {
                                return 0;
                              }
                              return a.joinedAt!.compareTo(b.joinedAt!);
                            });

                          return _CrewDetails(
                              crewName: crewName, members: members);
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
    required this.controller,
    required this.isJoining,
    required this.onJoin,
  });

  final TextEditingController controller;
  final bool isJoining;
  final VoidCallback onJoin;

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
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Crew name",
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
              : const Text("Join Crew"),
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
