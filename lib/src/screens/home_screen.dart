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

String todayKey() {
  final now = DateTime.now();
  return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CrewDirectoryScreen()),
    );
    if (result != null) {
      final record = result as ({String name, String password});
      _joinCrew(record.name, record.password);
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
                  StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .snapshots(),
                    builder: (context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> userDocSnap) {
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

                      return StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('crews')
                            .doc(crewId)
                            .snapshots(),
                        builder: (context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> crewSnap) {
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

                          return _CrewDetails(
                            crewId: crewId,
                            crewName: crewName,
                            currentUid: user.uid,
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

class _CrewDetails extends StatefulWidget {
  const _CrewDetails({
    required this.crewId,
    required this.crewName,
    required this.currentUid,
  });

  final String crewId;
  final String crewName;
  final String currentUid;

  @override
  State<_CrewDetails> createState() => _CrewDetailsState();
}

class _CrewDetailsState extends State<_CrewDetails> {
  final _taskController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  Future<void> _checkIn() async {
    await FirebaseFirestore.instance
        .collection('crews')
        .doc(widget.crewId)
        .collection('members')
        .doc(widget.currentUid)
        .update({'lastCheckInDate': todayKey()});
  }

  Future<void> _addTask() async {
    final text = _taskController.text.trim();
    if (text.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('crews')
        .doc(widget.crewId)
        .collection('tasks')
        .add({
      'text': text,
      'completed': false,
      'createdBy': user.uid,
      'createdByEmail': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'completedBy': null,
      'completedAt': null,
    });
    _taskController.clear();
  }

  Future<void> _toggleTask(String taskId, bool currentlyCompleted) async {
    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance
        .collection('crews')
        .doc(widget.crewId)
        .collection('tasks')
        .doc(taskId)
        .update({
      'completed': !currentlyCompleted,
      'completedBy': !currentlyCompleted ? user?.email : null,
      'completedAt':
          !currentlyCompleted ? FieldValue.serverTimestamp() : null,
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = todayKey();

    return Column(
      children: [
        Icon(Icons.groups,
                size: 48, color: Theme.of(context).colorScheme.primary)
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(begin: const Offset(0.8, 0.8)),
        const SizedBox(height: 12),
        Text(
          "You're in crew: ${widget.crewName}",
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
        const SizedBox(height: 16),
        StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('crews')
              .doc(widget.crewId)
              .collection('members')
              .orderBy('joinedAt')
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> membersSnap) {
            final docs = membersSnap.data?.docs ?? [];
            final selfDoc = docs.where((d) => d.id == widget.currentUid);
            final selfCheckedIn = selfDoc.isNotEmpty &&
                selfDoc.first.data()['lastCheckInDate'] == today;
            final checkedInCount = docs
                .where((d) => d.data()['lastCheckInDate'] == today)
                .length;

            return Column(
              children: [
                Text(
                  "Members (${docs.length}) · $checkedInCount checked in today",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                ...docs.map((d) {
                  final data = d.data();
                  final email = data['email'] as String? ?? 'Unknown';
                  final joinedAt =
                      (data['joinedAt'] as Timestamp?)?.toDate();
                  final checkedIn = data['lastCheckInDate'] == today;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          checkedIn
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: checkedIn ? Colors.greenAccent : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            joinedAt != null
                                ? "$email · joined ${joinedAt.day}/${joinedAt.month}/${joinedAt.year}"
                                : email,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: selfCheckedIn ? null : _checkIn,
                  icon: Icon(
                      selfCheckedIn ? Icons.check : Icons.check_circle_outline),
                  label: Text(
                      selfCheckedIn ? "Checked in for today" : "Check in today"),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          "Crew tasks",
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('crews')
              .doc(widget.crewId)
              .collection('tasks')
              .orderBy('createdAt')
              .snapshots(),
          builder: (context, AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> tasksSnap) {
            final docs = tasksSnap.data?.docs ?? [];
            if (docs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text("No tasks yet.",
                    style: TextStyle(color: Colors.grey)),
              );
            }
            return Column(
              children: docs.map((d) {
                final data = d.data();
                final text = data['text'] as String? ?? '';
                final completed = data['completed'] as bool? ?? false;
                return CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: completed,
                  onChanged: (_) => _toggleTask(d.id, completed),
                  title: Text(
                    text,
                    style: completed
                        ? const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey)
                        : null,
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _taskController,
                decoration: const InputDecoration(
                  hintText: "Add a task...",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _addTask(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _addTask,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}
