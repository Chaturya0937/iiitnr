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
        alignment: AlignmentGeometry.center,
        child: Column(
          children: [
            Text("Labs&Sports",style: TextStyle(fontWeight: FontWeight.w400,fontSize: 32.0),),
            FloatingActionButton(
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
            TextField(
              controller: labNameController,
              decoration: const InputDecoration(
                labelText: "Lab Name",
                hintText: "Enter the lab name",
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: inchargeEmailController,
              decoration: const InputDecoration(
                labelText: "Incharge Email",
                hintText: "Enter the email of the incharge",
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final labName = labNameController.text.trim();
                final inchargeEmail = inchargeEmailController.text.trim();

                if (labName.isNotEmpty && inchargeEmail.isNotEmpty) {
                  try {
                    // Create a new collection for the lab and add metadata doc
                    final labCollection = FirebaseFirestore.instance.collection(labName.toLowerCase() + "_equipment");

                    // Add a metadata document for the lab info
                    await FirebaseFirestore.instance.collection('labs').doc(labName.toLowerCase()).set({
                      'name': labName,
                      'incharge_email': inchargeEmail,
                      'created_at': FieldValue.serverTimestamp(),
                    });

                    // Optionally add an initial empty doc or setup
                    await labCollection.add({
                      'initialized': true,
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    Navigator.pop(context);
                  } catch (e) {
                    // Handle error or show feedback
                    print("Error adding lab: $e");
                  }
                } else {
                  // Show validation error
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
)
          ],
        ),
      ),
    );
  }
}