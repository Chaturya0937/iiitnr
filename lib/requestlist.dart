import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iiitnr/Requests.dart';


class StudentRequestListPage extends StatelessWidget {
  const StudentRequestListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    

    if (user == null || user.email == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    final email = user.email!;
    print('Fetching requests for email: $email');
    return Scaffold(
      appBar: AppBar(title: const Text("My Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('batchid')
            .where('Email', isEqualTo: email)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No requests yet"));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final batchId = doc['batchId'];

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.qr_code),
                  title: const Text("Equipment Request"),
                  subtitle: Text("Batch ID: ${batchId.substring(0, 8)}"),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StudentRespectiveRequests(batchid: batchId),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

