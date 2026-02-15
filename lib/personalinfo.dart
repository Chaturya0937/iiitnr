import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Personalinfo extends StatelessWidget {
  const Personalinfo({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Personal Info"),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: ColoredBox(color: Colors.black, child: SizedBox(height: 1.0)),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(userEmail).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          // Default to 100 if the field doesn't exist yet
          final int trustScore = data['trust_score'] ?? 100; 
          
          // Logic for visual feedback based on the score
          Color statusColor = trustScore > 80 
              ? Colors.green 
              : (trustScore > 50 ? Colors.orange : Colors.red);

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Visual Trust Score & Reward Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          "Account Standing", 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                        ),
                        const Divider(),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              height: 60, 
                              width: 60,
                              child: CircularProgressIndicator(
                                value: trustScore / 100,
                                backgroundColor: Colors.grey[200],
                                color: statusColor,
                                strokeWidth: 8,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "$trustScore%", 
                                  style: TextStyle(
                                    fontSize: 24, 
                                    fontWeight: FontWeight.bold, 
                                    color: statusColor
                                  )
                                ),
                                const Text("Trust Score", style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.discount, color: statusColor),
                              const SizedBox(width: 10),
                              const Text(
                                "Fine Discount Applied: ", 
                                style: TextStyle(fontWeight: FontWeight.w500)
                              ),
                              Text(
                                "$trustScore%", 
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  color: statusColor
                                )
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // User Details
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text("Registered Email"),
                  subtitle: Text(userEmail ?? "Not Logged In"),
                ),
                const ListTile(
                  leading: Icon(Icons.verified_user_outlined),
                  title: Text("Status"),
                  subtitle: Text("Verified IIITNR Student"),
                ),
                const Spacer(),
                const Text(
                  "Heuristic Trust Layer v1.0",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}