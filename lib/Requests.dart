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
  
  // *** DYNAMIC QR GENERATION LOGIC ***
  Stream<String> _streamRequests() {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null || user.email == null) {
      return Stream.value("No logged in user");
    }

    // Query all requests tied to the current user and batchId
    return FirebaseFirestore.instance
        .collection('Requests')
        .where('Email', isEqualTo: user.email)
        .where('batchId', isEqualTo: widget.batchid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return "No requests found";
      
      // Get the permission/lab name from the first document (they should all be the same)
      final String dynamicPermission = snapshot.docs.first.data()['permission'] ?? "Unknown";

      List<Map<String, dynamic>> allRequests = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        
        // Use the DYNAMICALLY fetched permission, ensuring the QR code matches the scanner
        data['permission'] = dynamicPermission; 
        
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        return data;
      }).toList();

      // IMPORTANT: If the request status is "pending" or "accepted", 
      // the QR code should be generated using the correct permission set by the student request.
      
      return jsonEncode(allRequests);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Equipment Requests Status")),
      body: StreamBuilder<String>(
        stream: _streamRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          if (data == "No requests found" || data == "No logged in user") {
            // Note: Removed pop here for better user experience, showing 'no content' is safer.
            return const Center(child: Text("No active requests to display."));
          }
          
          // Check if the data is a valid JSON array string containing requests 
          List<Map<String, dynamic>> parsedRequests;
          try {
            parsedRequests = List<Map<String, dynamic>>.from(jsonDecode(data));
          } catch (e) {
            return const Center(child: Text("Error parsing request data for QR code."));
          }

          // Determine the In-Charge/Lab Name for display only
          final displayLabName = parsedRequests.isNotEmpty 
              ? (parsedRequests.first['permission'] ?? 'Equipment') 
              : 'Unknown';

          return Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Text("Show this QR to the $displayLabName In-Charge", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    QrImageView(
                      data: data,
                      version: QrVersions.auto,
                      size: 250.0,
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    const Text("Requested Equipment (Pending):", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    
                    // Display Pending Requests
                    ...parsedRequests.where((req) => req['status'] == 'pending' || req['status'] == false).map((req) {
                      return Card(
                        child: ListTile(
                          title: Text("${req['Name']} : ${req['count']}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () async {
                              // Delete the pending request logic (kept the original structure)
                              final requestId = req['id'];
                              await FirebaseFirestore.instance.collection('Requests').doc(requestId).delete();
                              
                              final remainingRequests = await FirebaseFirestore.instance
                                  .collection('Requests')
                                  .where('batchId', isEqualTo: widget.batchid)
                                  .get();
                              
                              if (remainingRequests.docs.isEmpty) {
                                await FirebaseFirestore.instance
                                    .collection('batchid')
                                    .doc(widget.batchid)
                                    .delete();
                                
                                if (mounted && Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                }
                              }
                            },
                          ),
                        ),
                      );
                    }).toList(),
                    
                    const SizedBox(height: 16),
                    const Text("Accepted Equipment:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    
                    // Display Accepted Requests
                    ...parsedRequests.where((req) => req['status'] == true || req['status'] == 'accepted').map((req) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.check_circle, color: Colors.green),
                          title: Text("${req['Name']} : ${req['count']}"),
                        ),
                      );
                    }).toList(),
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
