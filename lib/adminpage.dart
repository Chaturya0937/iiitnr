import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iiitnr/HomePage.dart';
import 'package:iiitnr/personalinfo.dart';

// --- CONFIGURATION ---
// TODO: Replace this with your actual Web API Key from Firebase Console -> Project Settings -> General
const String _firebaseApiKey = "YOUR_WEB_API_KEY_HERE"; 

class adminPage extends StatelessWidget {
  const adminPage({super.key});

  /// Logic to handle Bulk Upload without logging out the Admin
  Future<void> _handleBulkUpload(BuildContext context) async {
    try {
      // 1. Pick the CSV file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null) return; // User canceled

      List<List<dynamic>> rows = [];

      // 2. Read file content based on platform (Web vs Mobile)
      if (kIsWeb) {
        // Web: Read bytes directly
        final bytes = result.files.first.bytes;
        if (bytes != null) {
          String csvString = utf8.decode(bytes);
          rows = const CsvToListConverter().convert(csvString);
        }
      } else {
        // Mobile: Read from path
        final path = result.files.single.path;
        if (path != null) {
          final file = File(path);
          final input = file.openRead();
          rows = await input
              .transform(utf8.decoder)
              .transform(const CsvToListConverter())
              .toList();
        }
      }

      if (rows.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("File is empty or could not be read.")),
          );
        }
        return;
      }

      // 3. Process the Rows
      // Expected CSV Format: Name, Roll Number, Branch, Email
      // We skip the first row assuming it's a header
      int successCount = 0;
      int failCount = 0;

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Processing file... please wait.")),
        );
      }

      // Loop starts at 1 to skip headers. If no headers, start at 0.
      for (var i = 1; i < rows.length; i++) {
        var row = rows[i];
        
        // Basic validation to ensure row has enough columns
        if (row.length < 4) continue; 

        String name = row[0].toString().trim();
        String rollNumber = row[1].toString().trim();
        String branch = row[2].toString().trim();
        String email = row[3].toString().trim();
        String defaultPassword = "IIITNR@$rollNumber"; // Example default password strategy

        if (email.isEmpty || name.isEmpty) continue;

        bool success = await _createStudentRestApi(
          name: name,
          email: email,
          password: defaultPassword,
          rollNumber: rollNumber,
          branch: branch,
        );

        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      }

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Import Complete"),
            content: Text("Successfully added: $successCount students.\nFailed/Skipped: $failCount."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK"),
              )
            ],
          ),
        );
      }

    } catch (e) {
      print("Bulk Upload Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error processing file: $e")),
        );
      }
    }
  }

  /// Helper: Creates user via REST API to verify Admin session stays active
  Future<bool> _createStudentRestApi({
    required String name,
    required String email,
    required String password,
    required String rollNumber,
    required String branch,
  }) async {
    const String url = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_firebaseApiKey";

    try {
      final response = await http.post(
        Uri.parse(url),
        body: json.encode({
          "email": email,
          "password": password,
          "returnSecureToken": true,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        String newUserId = responseData['localId'];

        // Add to Firestore using the standard SDK (safe for Admin)
        await FirebaseFirestore.instance.collection('Users').doc(newUserId).set({
          'name': name,
          'email': email,
          'roll_number': rollNumber,
          'branch': branch,
          'role': 'student',
          'created_at': FieldValue.serverTimestamp(),
          'is_active': true,
        });
        return true;
      } else {
        print("Failed to create $email: ${responseData['error']['message']}");
        return false;
      }
    } catch (e) {
      print("System Error creating $email: $e");
      return false;
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
        child: SingleChildScrollView( // Added ScrollView to prevent overflow on smaller screens
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "Labs & Sports Admin Portal", 
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 24.0, color: Color.fromARGB(255, 0, 72, 126)),
                ),
              ),
              
              // --- EXISTING BUTTON: CREATE LAB ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: FloatingActionButton.extended(
                  heroTag: "btn1", // Unique tag for hero animation
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
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Lab '$rawLabName' created and Incharge role assigned!")),
                                    );
                                    Navigator.pop(context); // Close the modal
                                  }
                                } on FirebaseException catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Firebase Error: Failed to add lab. ${e.message}")),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("General Error: Failed to add lab. $e")),
                                    );
                                  }
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
                  icon: const Icon(Icons.add_business),
                  label: const Text("Create New Lab Portal"),
                ),
              ),

              // --- NEW BUTTON: BULK UPLOAD STUDENTS ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: FloatingActionButton.extended(
                  heroTag: "btn2", // Unique tag to prevent hero tag conflict
                  backgroundColor: Colors.green, // Different color to distinguish
                  onPressed: () => _handleBulkUpload(context),
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Import Students (CSV)"),
                ),
              ),
              
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.0),
                child: Text(
                  "Note: CSV format should be: Name, Roll Number, Branch, Email",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
