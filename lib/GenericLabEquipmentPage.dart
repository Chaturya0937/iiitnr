import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class GenericLabEquipmentPage extends StatefulWidget {
  final String labName;
  final String collectionName;

  const GenericLabEquipmentPage({
    super.key,
    required this.labName,
    required this.collectionName,
  });

  @override
  State<GenericLabEquipmentPage> createState() => _GenericLabEquipmentPageState();
}

class _GenericLabEquipmentPageState extends State<GenericLabEquipmentPage> {
  final Map<String, int> selectedItems = {};

  void _submitRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    if (selectedItems.isEmpty || selectedItems.values.every((v) => v == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No items selected")),
      );
      return;
    }

    final batchId = const Uuid().v4();
    final batch = FirebaseFirestore.instance.batch();
    final now = DateTime.now();

    selectedItems.forEach((name, count) {
      if (count > 0) {
        final docRef = FirebaseFirestore.instance.collection('Requests').doc();
        batch.set(docRef, {
          'Email': user.email,
          'Name': name, 
          'count': count,
          'labName': widget.labName,
          'equipment_collection': widget.collectionName,
          'status': false, // false = pending
          'batchId': batchId,
          // DATA ANALYTICS FIELDS
          'timestamp': FieldValue.serverTimestamp(), 
          'month_year': "${now.month}-${now.year}", // For easy monthly filtering
        });
      }
    });

    try {
      await batch.commit();
      
      // Update the batchid collection so students can see their request list
      await FirebaseFirestore.instance.collection('batchid').doc(batchId).set({
        'batchId': batchId,
        'Email': user.email,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() => selectedItems.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Request submitted successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("${widget.labName} Equipment"),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: ColoredBox(color: Colors.black, child: SizedBox(height: 1.0)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('equipment')
                  .doc(widget.collectionName)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("No equipment found."));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final List<dynamic> equipmentList = data['equipment'] ?? [];

                if (equipmentList.isEmpty) {
                  return const Center(child: Text("Lab inventory is empty."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: equipmentList.length,
                  itemBuilder: (context, index) {
                    final item = equipmentList[index] as Map<String, dynamic>;
                    final String name = item['Name'] ?? 'Unknown Item';
                    final int available = (item['count'] ?? 0) as int;
                    final int selected = selectedItems[name] ?? 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("In Stock: $available"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: selected > 0
                                  ? () => setState(() => selectedItems[name] = selected - 1)
                                  : null,
                            ),
                            Text('$selected', style: const TextStyle(fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                              onPressed: selected < available
                                  ? () => setState(() => selectedItems[name] = selected + 1)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 72, 126),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _submitRequest,
              child: const Text("Confirm Request", style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}