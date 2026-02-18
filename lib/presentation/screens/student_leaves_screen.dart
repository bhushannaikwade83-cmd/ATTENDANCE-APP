import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentLeavesScreen extends StatelessWidget {
  const StudentLeavesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Leave Requests"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      // Leave application feature removed - student role no longer exists
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('leaves')
            .where('studentId', isEqualTo: user?.uid)
            .orderBy('appliedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No leave requests found."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final status = data['status'] ?? 'pending';
              final reason = data['reason'] ?? 'No reason';
              
              Color color = Colors.orange;
              if (status == 'approved') color = Colors.green;
              if (status == 'rejected') color = Colors.red;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(Icons.description, color: color)),
                  title: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  subtitle: Text("Reason: $reason"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
