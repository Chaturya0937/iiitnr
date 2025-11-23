import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iiitnr/HomePage.dart';
import 'package:iiitnr/personalinfo.dart';

class adminPage extends StatelessWidget {
  const adminPage({super.key});

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
            child: const CircleAvatar(
              radius: 15,
              backgroundColor: Color.fromARGB(255, 91, 169, 237),
              child: Icon(Icons.person, size: 25, color: Colors.white),
            ),
          ),
        ),
        title: const Text("Welcome Admin"),
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
        alignment: Alignment.center, // Fixed alignment
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                "Labs & Sports Admin Portal", 
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24.0, color: Color.fromARGB(255, 0, 72, 126)),
              ),
            ),
            FloatingActionButton.extended( // Changed to extended for better visibility
              onPressed: () {
                final TextEditingController labNameController = TextEditingController();
                final TextEditingController inchargeEmailController = TextEditingController();

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
                        const Text("Add New Lab Portal", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: labNameController,
                          decoration: const InputDecoration(
                            labelText: "Lab Name (e.g., Robotics)",
                            hintText: "Enter the lab name",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: inchargeEmailController,
                          decoration: const InputDecoration(
                            labelText: "Incharge Email (must be registered)",
                            hintText: "Enter the email of the incharge",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          // <<< CRITICAL FIX: MARKED ASYNC >>>
                          onPressed: () async { 
                            final rawLabName = labNameController.text.trim();
                            final inchargeEmail = inchargeEmailController.text.trim();
                            
                            // Normalizing the name (removes spaces, capitalizes first letter)
                            final normalizedLabName = rawLabName.replaceAll(RegExp(r'\s+'), '');
                            
                            final newRole = "${normalizedLabName}Incharge";
                            final collectionName = "${normalizedLabName.toLowerCase()}_equipment";

                            if (rawLabName.isEmpty || inchargeEmail.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please fill in all fields")),
                              );
                              return;
                            }

                            try {
                              // --- STEP 1: Find User UID by Email ---
                              final userQuery = await FirebaseFirestore.instance.collection("Users")
                                  .where("email", isEqualTo: inchargeEmail)
                                  .limit(1)
                                  .get();

                              if (userQuery.docs.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Error: Incharge email not found in Users database.")),
                                );
                                return;
                              }

                              final inchargeUid = userQuery.docs.first.id;

                              // --- STEP 2: Create FIREBASE DATA STRUCTURES & METADATA ---
                              // Create lab metadata document
                              await FirebaseFirestore.instance.collection('labs').doc(normalizedLabName.toLowerCase()).set({
                                'name': rawLabName,
                                'incharge_email': inchargeEmail,
                                'created_at': FieldValue.serverTimestamp(),
                                'collection_name': collectionName, 
                                'incharge_role': newRole, 
                                'scanner_permission': normalizedLabName,
                              });

                              // Initialize the new equipment collection
                              await FirebaseFirestore.instance.collection(collectionName).doc('metadata').set({'initialized': true});

                              // --- STEP 3: Assign the new Dynamic Role ---
                              await FirebaseFirestore.instance.collection('Users').doc(inchargeUid).update({
                                'role': newRole, 
                              });
                              
                              // Success Feedback
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Lab '$rawLabName' created and Incharge role assigned!")),
                              );
                              Navigator.pop(context); // Close the modal
                            } on FirebaseException catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Firebase Error: Failed to add lab. ${e.message}")),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("General Error: Failed to add lab. $e")),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text("Create Lab"),
                        ),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_business), // Better icon for "add lab"
              label: const Text("Create New Lab Portal"),
            )
          ],
        ),
      ),
    );
  }
}
