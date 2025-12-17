import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class StudentRespectiveRequests extends StatefulWidget {
  final String batchid;
  const StudentRespectiveRequests({super.key, required this.batchid});

  @override
  State<StudentRespectiveRequests> createState() => _StudentRespectiveRequestsState();
}

class _StudentRespectiveRequestsState extends State<StudentRespectiveRequests> {
  Stream<String> _streamRequests() {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      return Stream.value("No logged in user");
    }

    return FirebaseFirestore.instance
        .collection('Requests')
        .where('Email', isEqualTo: user.email)
        .where('batchId', isEqualTo: widget.batchid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return "No requests found";
      List<Map<String, dynamic>> allRequests = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['permission'] = "Sports";
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        return data;
      }).toList();

      return jsonEncode(allRequests);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sports Requests")),
      body: StreamBuilder<String>(
        stream: _streamRequests(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          if (data == "No requests found" || data == "No logged in user") {
            Future.microtask(() {
              if (Navigator.canPop(context)) Navigator.pop(context);
            });
            return const SizedBox();
          }
          return Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 250.0,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    const Text("Requested Equipment:", style: TextStyle(fontSize: 18)),
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('Requests')
                          .where('Email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
                          .where('batchId', isEqualTo: widget.batchid)
                          .where('status', isEqualTo: false)
                          .get(),
                      builder: (context, requestSnapshot) {
                        if (requestSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!requestSnapshot.hasData || requestSnapshot.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text("No pending requests", style: TextStyle(color: Colors.grey)),
                          );
                        }
                        return Column(
                          children: requestSnapshot.data!.docs.map((doc) {
                            final name = doc['Name'];
                            final count = doc['count'];
                            return Card(
                              child: ListTile(
                                title: Text("$name : $count"),
                                trailing: IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () async {
                                    // Delete the pending request
                                    await FirebaseFirestore.instance.collection('Requests').doc(doc.id).delete();
                                    
                                    // Check if there are any remaining requests for this batchId
                                    final remainingRequests = await FirebaseFirestore.instance
                                        .collection('Requests')
                                        .where('batchId', isEqualTo: widget.batchid)
                                        .get();
                                    
                                    // If no requests remain, delete the batchid document
                                    if (remainingRequests.docs.isEmpty) {
                                      await FirebaseFirestore.instance
                                          .collection('batchid')
                                          .doc(widget.batchid)
                                          .delete();
                                      
                                      // Navigate back if this was the last item
                                      if (mounted && Navigator.canPop(context)) {
                                        Navigator.pop(context);
                                      }
                                    }
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text("Accepted Equipment:", style: TextStyle(fontSize: 18)),
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('Requests')
                          .where('Email', isEqualTo: FirebaseAuth.instance.currentUser?.email)
                          .where('batchId', isEqualTo: widget.batchid)
                          .where('status', isEqualTo: true)
                          .get(),
                      builder: (context, acceptedSnapshot) {
                        if (acceptedSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!acceptedSnapshot.hasData || acceptedSnapshot.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text("No accepted requests", style: TextStyle(color: Colors.grey)),
                          );
                        }
                        return Column(
                          children: acceptedSnapshot.data!.docs.map((doc) {
                            final name = doc['Name'];
                            final count = doc['count'];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.check_circle, color: Colors.green),
                                title: Text("$name : $count"),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}



