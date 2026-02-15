import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iiitnr/labqr.dart';

class LabRequests extends StatelessWidget {
  final String collectionName;
  final String labName;
  const LabRequests({super.key, required this.collectionName,required this.labName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Requests for ${collectionName.split('_').first.toUpperCase()}",
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(height: 1, thickness: 1, color: Colors.black),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Requests')
            .where('equipment_collection', isEqualTo: collectionName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No requests."));
          }

          final allRequests = snapshot.data!.docs;

          // Split into pending (status == false) and accepted (status == true)
          final pendingRequests = allRequests.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == false;
          }).toList();

          final acceptedRequests = allRequests.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == true;
          }).toList();

          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Requested Equipment:"),
              ),
              if (pendingRequests.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text("No pending requests."),
                )
              else
                ...pendingRequests.map((request) {
                  final data = request.data() as Map<String, dynamic>;
                  final studentEmail = data['Email'] ?? 'N/A';
                  final batchId = data['batchId'] ?? 'N/A';
                  final requestedItem = data['Name'] ?? 'Unknown Item';
                  final count = data['count'] ?? 0;
                  final timestamp = data['createdAt'] is Timestamp
                      ? (data['createdAt'] as Timestamp).toDate().toString()
                      : 'N/A';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Labqr(batchid: batchId,role:labName),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 10,
                      ),
                      child: ListTile(
                        title: Text("$requestedItem x $count"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Batch ID: $batchId"),
                            Text("Student: $studentEmail"),
                            Text("Requested on: $timestamp"),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Accept => status = true
                            // IconButton(
                            //   icon: const Icon(Icons.check, color: Colors.green),
                            //   onPressed: () => _handleRequest(context, request.id, true),
                            // ),
                            // Reject => status = false but mark rejected flag
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('Requests')
                                      .doc(request.id)
                                      .delete(); // delete the document
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Request deleted'),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to delete: $e'),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Accepted Equipment:"),
              ),
              if (acceptedRequests.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text("No accepted requests yet."),
                )
              else
                ...acceptedRequests.map((request) {
                  final data = request.data() as Map<String, dynamic>;
                  final studentEmail = data['Email'] ?? 'N/A';
                  final batchId = data['batchId'] ?? 'N/A';
                  final requestedItem = data['Name'] ?? 'Unknown Item';
                  final count = data['count'] ?? 0;
                  final timestamp = data['createdAt'] is Timestamp
                      ? (data['createdAt'] as Timestamp).toDate().toString()
                      : 'N/A';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Labqr(batchid: batchId,role:labName),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 10,
                      ),
                      child: ListTile(
                        title: Text("$requestedItem x $count"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Batch ID: $batchId"),
                            Text("Student: $studentEmail"),
                            Text("Requested on: $timestamp"),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  // approve = true  -> status: true
  // approve = false -> status: false + rejected: true
  Future<void> _handleRequest(
    BuildContext context,
    String requestId,
    bool approve,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('Requests')
          .doc(requestId)
          .update({
            'status': approve, // true or false
            if (!approve) 'rejected': true,
            'processed_at': FieldValue.serverTimestamp(),
            'processed_by':
                FirebaseAuth.instance.currentUser?.email ?? 'Unknown In-Charge',
          });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Request $requestId ${approve ? 'accepted' : 'rejected'}!",
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to process request: $e")));
    }
  }
}
