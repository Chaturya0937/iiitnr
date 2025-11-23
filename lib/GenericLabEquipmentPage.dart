import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GenericLabEquipmentPage extends StatefulWidget {
  final String labName;
  final String collectionName; // e.g., 'graphicslab_equipment'

  const GenericLabEquipmentPage({
    super.key, 
    required this.labName, 
    required this.collectionName
  });

  @override
  State<GenericLabEquipmentPage> createState() => _GenericLabEquipmentPageState();
}

class _GenericLabEquipmentPageState extends State<GenericLabEquipmentPage> {
  // Key used to tie all items in a single request batch together
  final String batchId = DateTime.now().millisecondsSinceEpoch.toString(); 

  // Map to store current request counts for the current session: {itemName: count}
  final Map<String, int> requestItems = {}; 

  // Function to submit a single request for an item
  Future<void> submitRequest(
      String itemName, int count, String availableQuantity) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      // Display a Snackbar instead of an alert
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication error. Please log in again.")),
      );
      return;
    }

    if (count <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a valid quantity.")),
      );
      return;
    }

    try {
      // Get the current available quantity to prevent over-requesting
      final currentAvailable = int.tryParse(availableQuantity) ?? 0;
      if (count > currentAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Only $currentAvailable available.")),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('Requests').add({
        'Email': user.email,
        'Name': itemName,
        'count': count,
        'batchId': batchId,
        'status': 'pending', // Initial status
        'createdAt': FieldValue.serverTimestamp(),
        'equipment_collection': widget.collectionName, // For InCharge filtering
        'permission': widget.labName, // For InChargeScanner verification
      });

      // Update the local state (optional, depends on your full request flow)
      // For a full system, you might clear local request after submission or move to another screen.
      // For now, we update local state and notify.
      setState(() {
        requestItems.clear(); 
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$count x $itemName requested successfully!")),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit request: $e")),
      );
    }
  }

  // Widget builder for quantity selector and submit button
  Widget _buildRequestRow(DocumentSnapshot itemDoc) {
    final data = itemDoc.data() as Map<String, dynamic>;
    final itemName = data['name'] ?? 'Unknown Item';
    final available = data['count']?.toString() ?? 'N/A';
    
    // Ensure this item name has an entry in our request map
    requestItems.putIfAbsent(itemName, () => 0);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: ListTile(
        title: Text(itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Available: $available"),
        trailing: SizedBox(
          width: 150,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Decrement button
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.red),
                onPressed: () {
                  if (requestItems[itemName]! > 0) {
                    setState(() {
                      requestItems[itemName] = requestItems[itemName]! - 1;
                    });
                  }
                },
              ),
              // Quantity text
              Text(requestItems[itemName].toString()),
              // Increment button
              IconButton(
                icon: const Icon(Icons.add, color: Colors.green),
                onPressed: () {
                  // Only allow increment if less than available stock
                  final current = requestItems[itemName]!;
                  final max = int.tryParse(available) ?? 0;

                  if (current < max) {
                    setState(() {
                      requestItems[itemName] = current + 1;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        // Submit request for the selected item
        onTap: () {
          if (requestItems[itemName]! > 0) {
            submitRequest(itemName, requestItems[itemName]!, available);
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text("Select a quantity greater than zero.")),
             );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.labName} Equipment"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0), 
          child: Container(color: Colors.black, height: 1.0),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Available Equipment in ${widget.labName}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // --- DYNAMICALLY FETCH EQUIPMENT INVENTORY ---
              stream: FirebaseFirestore.instance
                  .collection(widget.collectionName) 
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No equipment found in this lab's inventory."));
                }

                // Filter out the 'metadata' document if present
                final equipmentDocs = snapshot.data!.docs.where((doc) => doc.id != 'metadata').toList();

                if (equipmentDocs.isEmpty) {
                  return const Center(child: Text("Inventory is currently empty."));
                }

                return ListView.builder(
                  itemCount: equipmentDocs.length,
                  itemBuilder: (context, index) {
                    return _buildRequestRow(equipmentDocs[index]);
                  },
                );
              },
            ),
          ),
          
          // Floating Button/Summary for current request session (Optional: Depends on flow)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to the student request tracking page (lib/RequestNavigationPage.dart)
                // You may want to check if any requests are pending before navigating
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Navigating to your Requests overview page...")),
                );
                // You'll need to adapt the StudentRequest tracking page to dynamically handle the request flow
                // For demonstration, this button just gives feedback.
              },
              icon: const Icon(Icons.send),
              label: const Text("View Pending/Accepted Requests"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
