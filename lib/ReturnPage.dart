import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReturnEquipmentPage extends StatelessWidget {
  const ReturnEquipmentPage({super.key});

  // Business Logic: ₹10 per hour penalty after 24 hours
  double calculateFine(Timestamp borrowedAt, int trustScore) {
    DateTime borrowed = borrowedAt.toDate();
    DateTime deadline = borrowed.add(const Duration(hours: 24));
    DateTime now = DateTime.now();

    if (now.isBefore(deadline)) return 0.0;

    int hoursOverdue = now.difference(deadline).inHours;
    double baseFine = hoursOverdue * 10.0;
    
    // Apply trust discount (e.g. 90% score = 90% discount on fine)
    double discount = (trustScore / 100) * baseFine;
    return baseFine - discount;
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    final user = FirebaseAuth.instance.currentUser;

    print('userEmail: $userEmail');
    return Scaffold(
      appBar: AppBar(
        title: const Text("Current Loans"),
        backgroundColor: const Color.fromARGB(255, 0, 72, 126),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // Step 1: Get user's trust score for the calculation
        stream: FirebaseFirestore.instance
      .collection('Users') // ✅ capital U
      .doc(user!.uid)      // ✅ UID
      .snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          final int trustScore = userSnapshot.data?['trust_score'] ?? 0;

          return StreamBuilder<QuerySnapshot>(
            // Step 2: Get accepted requests that need to be returned
            stream: FirebaseFirestore.instance
                .collection('Requests')
                .where('Email', isEqualTo: userEmail)
                .where('status', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("You have no active equipment loans."));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final Timestamp ts = data['timestamp'] ?? Timestamp.now();
                  final double finalFine = calculateFine(ts, trustScore);

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(data['Name'] ?? "Item", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              Chip(label: Text("Trust: $trustScore%"), backgroundColor: Colors.green[100]),
                            ],
                          ),
                          Text("Lab: ${data['labName']}"),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Calculated Fine:"),
                              Text("₹${finalFine.toStringAsFixed(2)}", 
                                style: TextStyle(
                                  color: finalFine > 0 ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16
                                )
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 45)
                            ),
                            onPressed: () {
                              // Logic for generating Return QR or settling fine
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Return QR Generated. Please visit the lab."))
                              );
                            },
                            child: const Text("Generate Return QR"),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}