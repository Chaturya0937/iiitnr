import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iiitnr/GenericInchargePage.dart';
import 'package:iiitnr/GenericLabEquipmentPage.dart';
import 'package:iiitnr/HomePage.dart';
import 'package:iiitnr/personalinfo.dart';

class adminPage extends StatefulWidget {
  const adminPage({super.key});

  @override
  State<adminPage> createState() => _adminPageState();
}

class _adminPageState extends State<adminPage> {
   final TextEditingController labNameController = TextEditingController();
   final TextEditingController inchargeEmailController = TextEditingController();
  @override
    void dispose() {
     
      labNameController.dispose();
      inchargeEmailController.dispose();
      super.dispose();
    }
  // Add this method inside _adminPageState class (before build method)
Future<void> _deleteLab(BuildContext context, String labDocId, String labName, String inchargeEmail, String collectionName, String newRole) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Lab'),
      content: Text('Are you sure you want to delete "$labName" and all its equipment data? This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  try {
    // Step 1: Find and reset incharge role
    final userQuery = await FirebaseFirestore.instance
        .collection("Users")
        .where("email", isEqualTo: inchargeEmail)
        .limit(1)
        .get();

    if (userQuery.docs.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(userQuery.docs.first.id)
          .update({'role': 'student'}); // Reset to default role
    }

    // Step 2: Delete lab document
    await FirebaseFirestore.instance.collection('labs').doc(labDocId).delete();

    // Step 3: Delete equipment metadata
    await FirebaseFirestore.instance.collection('equipment').doc(collectionName).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lab "$labName" deleted successfully.')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error deleting lab: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    

    
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),

      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0), // optional padding for alignment
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Personalinfo()),
              );
            },
            child: CircleAvatar(
              radius: 15,
              backgroundColor: const Color.fromARGB(255, 91, 169, 237),
              child: Icon(Icons.person, size: 25, color: Colors.white),
            ),
          ),
        ),
        title: const Text("Welcome"),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // After logout, redirect to login page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0), // height of the black line
          child: Container(color: Colors.black, height: 1.0),
        ),
      ),
      body: Align(
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Labs&Sports", style: TextStyle(fontWeight: FontWeight.w400, fontSize: 32.0),),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('labs')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error loading labs: ${snapshot.error}",
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("No labs currently registered."),
                    );
                  }

                  final labDocs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: labDocs.length,
                    itemBuilder: (context, index) {
                      final lab = labDocs[index];
                      final labName =
                          lab['name'] as String? ?? 'Unnamed Lab';
                      final collectionName =
                          lab['collection_name'] as String? ?? '';
                      if (collectionName.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Card(
  margin: const EdgeInsets.symmetric(vertical: 8),
  child: ListTile(
    title: Text(labName),
    subtitle: const Text('Tap to view & request equipment'),
    trailing: IconButton(
      icon: const Icon(Icons.delete, color: Colors.red),
      onPressed: () => _deleteLab(
        context,
        lab.id,  // labDocId
        labName,
        lab['incharge_email'] as String? ?? '',
        collectionName,
        lab['incharge_role'] as String? ?? '',
      ),
    ),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LabIncharge(role: labName),
        ),
      );
    },
  ),
);

                    },
                  );
                },
              ),
            ),

            FloatingActionButton(
              onPressed: () {
                

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 24,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: labNameController,
                          decoration: const InputDecoration(
                            labelText: "Lab Name",
                            hintText: "Enter the lab name (e.g., Graphics Lab)",
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: inchargeEmailController,
                          decoration: const InputDecoration(
                            labelText: "Incharge Email",
                            hintText: "Enter the email of the incharge (must be registered)",
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            final labName = labNameController.text.trim();
                            final inchargeEmail = inchargeEmailController.text.trim();

                            // Create the dynamic role and collection names
                            final normalizedLabName = labName.replaceAll(' ', '');
                            final newRole = "${normalizedLabName}";
                            final collectionName = "${normalizedLabName}equipment";


                            if (labName.isNotEmpty && inchargeEmail.isNotEmpty) {
                              try {
                                // --- STEP 1: Find User UID by Email ---
                                final userQuery = await FirebaseFirestore.instance
                                    .collection("Users")
                                    .where("email", isEqualTo: inchargeEmail)
                                    .limit(1)
                                    .get();

                                if (userQuery.docs.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Incharge email not found. User must have registered first.")),
                                  );
                                  return;
                                }

                                final inchargeUid = userQuery.docs.first.id;

                                // --- STEP 2: Create Firebase Data Structures & Metadata ---
                                await FirebaseFirestore.instance.collection('labs').doc(labName.toLowerCase()).set({
                                  'name': labName,
                                  'incharge_email': inchargeEmail,
                                  'created_at': FieldValue.serverTimestamp(),
                                  'collection_name': collectionName,
                                  'incharge_role': newRole,
                                  'scanner_permission': normalizedLabName,
                                });

                                // Initialize the new equipment collection
                                await FirebaseFirestore.instance.collection('equipment').doc(collectionName).set({'initialized': true});


                                // --- STEP 3: Assign the new Dynamic Role ---
                                await FirebaseFirestore.instance.collection('Users').doc(inchargeUid).update({
                                  'role': newRole,
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Lab '$labName' and Incharge role assigned successfully.")),
                                );
                                Navigator.pop(context); // Close the modal
                              } on FirebaseException catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Firebase Error: ${e.message}")),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("General Error: $e")),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please fill in all fields")),
                              );
                            }
                          },
                          child: const Text("Add Lab"),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }
}