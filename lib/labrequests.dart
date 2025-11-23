import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LabRequests extends StatelessWidget {
  // NEW: Accepts the dynamic equipment collection name
  final String collectionName; 
  
  const LabRequests({super.key, required this.collectionName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Requests for ${collectionName.split('_').first.toUpperCase()}"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.black, height: 1.0),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // --- DYNAMICALLY QUERY THE REQUESTS COLLECTION ---
        // Assuming requests are stored in a 'Requests' subcollection 
        // within the specific equipment collection (e.g., 'graphicslab_equipment/Requests')
        stream: FirebaseFirestore.instance
            .collection('Requests') // Assuming a common 'Requests' collection for all, filtered by collectionName
            .where('equipment_collection', isEqualTo: collectionName) // NEW: Filter by the target collection name
            .where('status', isEqualTo: 'pending') // Assuming a status field exists
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No pending requests."));
          }

          final pendingRequests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: pendingRequests.length,
            itemBuilder: (context, index) {
              final request = pendingRequests[index];
              final data = request.data() as Map<String, dynamic>;
              
              // Safely extract data fields
              final studentEmail = data['Email'] ?? 'N/A';
              final batchId = data['batchId'] ?? 'N/A';
              final requestedItem = data['Name'] ?? 'Unknown Item';
              final count = data['count'] ?? 0;
              final timestamp = data['createdAt'] is Timestamp 
                  ? (data['createdAt'] as Timestamp).toDate().toString() 
                  : 'N/A';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
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
                      // Approve Button
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _handleRequest(context, request.id, true),
                      ),
                      // Reject Button
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _handleRequest(context, request.id, false),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Function to approve or reject a request
  Future<void> _handleRequest(BuildContext context, String requestId, bool approve) async {
    try {
      await FirebaseFirestore.instance
          .collection('Requests')
          .doc(requestId)
          .update({
        'status': approve ? 'accepted' : 'rejected',
        'processed_at': FieldValue.serverTimestamp(),
        'processed_by': FirebaseAuth.instance.currentUser?.email ?? 'Unknown In-Charge',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Request $requestId ${approve ? 'Approved' : 'Rejected'}!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to process request: $e")),
      );
    }
  }
}
