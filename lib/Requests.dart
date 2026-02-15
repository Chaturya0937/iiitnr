import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class StudentRespectiveRequests extends StatefulWidget {
  final String batchid;
  const StudentRespectiveRequests({super.key, required this.batchid});

  @override
  State<StudentRespectiveRequests> createState() =>
      _StudentRespectiveRequestsState();
}

class _StudentRespectiveRequestsState
    extends State<StudentRespectiveRequests> {

  /// 🔒 Converts all Firestore Timestamps → String (JSON safe)
  Map<String, dynamic> _sanitizeMap(Map<String, dynamic> data) {
    final Map<String, dynamic> clean = {};

    data.forEach((key, value) {
      if (value is Timestamp) {
        clean[key] = value.toDate().toIso8601String();
      } else {
        clean[key] = value;
      }
    });

    return clean;
  }

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
      if (snapshot.docs.isEmpty) {
        return "No requests found";
      }

      List<Map<String, dynamic>> allRequests = snapshot.docs.map((doc) {
        final rawData = doc.data();
        final data = _sanitizeMap(rawData);

        data['id'] = doc.id;
        data['permission'] = "Sports";

        return data;
      }).toList();

      debugPrint("FINAL QR DATA: $allRequests");

      return jsonEncode(allRequests);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Requests")),
      body: StreamBuilder<String>(
        stream: _streamRequests(),
        builder: (context, snapshot) {
          debugPrint("Stream state: ${snapshot.connectionState}");
          debugPrint("Has data: ${snapshot.hasData}");
          debugPrint("Has error: ${snapshot.hasError}");
          debugPrint("Error: ${snapshot.error}");

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

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

              /// ✅ QR CODE
              Center(
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 250,
                  backgroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    const Text(
                      "Requested Equipment:",
                      style: TextStyle(fontSize: 18),
                    ),

                    /// 🔄 Pending Requests
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('Requests')
                          .where('Email',
                              isEqualTo:
                                  FirebaseAuth.instance.currentUser?.email)
                          .where('batchId', isEqualTo: widget.batchid)
                          .where('status', isEqualTo: false)
                          .get(),
                      builder: (context, requestSnapshot) {
                        if (requestSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!requestSnapshot.hasData ||
                            requestSnapshot.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              "No pending requests",
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return Column(
                          children:
                              requestSnapshot.data!.docs.map((doc) {
                            return Card(
                              child: ListTile(
                                title: Text(
                                    "${doc['Name']} : ${doc['count']}"),
                                trailing: IconButton(
                                  icon: const Icon(Icons.cancel,
                                      color: Colors.red),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('Requests')
                                        .doc(doc.id)
                                        .delete();

                                    final remaining = await FirebaseFirestore
                                        .instance
                                        .collection('Requests')
                                        .where('batchId',
                                            isEqualTo: widget.batchid)
                                        .get();

                                    if (remaining.docs.isEmpty) {
                                      await FirebaseFirestore.instance
                                          .collection('batchid')
                                          .doc(widget.batchid)
                                          .delete();

                                      if (mounted &&
                                          Navigator.canPop(context)) {
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
                    const Text(
                      "Accepted Equipment:",
                      style: TextStyle(fontSize: 18),
                    ),

                    /// ✅ Accepted Requests
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('Requests')
                          .where('Email',
                              isEqualTo:
                                  FirebaseAuth.instance.currentUser?.email)
                          .where('batchId', isEqualTo: widget.batchid)
                          .where('status', isEqualTo: true)
                          .get(),
                      builder: (context, acceptedSnapshot) {
                        if (acceptedSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (!acceptedSnapshot.hasData ||
                            acceptedSnapshot.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              "No accepted requests",
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return Column(
                          children:
                              acceptedSnapshot.data!.docs.map((doc) {
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.check_circle,
                                    color: Colors.green),
                                title: Text(
                                    "${doc['Name']} : ${doc['count']}"),
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
