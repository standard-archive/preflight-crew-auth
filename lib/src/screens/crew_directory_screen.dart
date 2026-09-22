import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";

class CrewDirectoryScreen extends StatelessWidget {
  const CrewDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Browse Crews")),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('crews')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  "No crews yet. Go back and create the first one!",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final name = data['name'] as String? ?? docs[index].id;
              final memberCount = data['memberCount'] as int? ?? 0;

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.groups),
                  title: Text(name),
                  subtitle: Text(
                    memberCount == 1
                        ? "1 member"
                        : "$memberCount members",
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, name),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
