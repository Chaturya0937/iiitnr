import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iiitnr/Adminpage.dart';
import 'package:iiitnr/IotIncharge.dart';
import 'package:iiitnr/StudentPage.dart';
import 'package:iiitnr/sportsincharge.dart';
import 'package:iiitnr/DnpIncharge.dart';
import 'package:iiitnr/GenericInchargePage.dart'; // <--- NEW: Generic handler for new labs

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Utility function to extract the name part of the role (e.g., 'GraphicsLab' from 'GraphicsLabIncharge')
  String? _extractInchargeName(String role) {
    if (role.toLowerCase().endsWith("incharge")) {
      return role.substring(0, role.length - "incharge".length);
    }
    return null;
  }

  Future<void> loginWithEmailAndPassword() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      final login = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = login.user?.uid;
      
      if (uid != null) {
        final userDoc =
            await FirebaseFirestore.instance.collection("Users").doc(uid).get();
            
        if (userDoc.exists) {
          final role = userDoc["role"] as String?; // Ensure role is treated as String
          
          if (role == null) {
            // Handle case where role field might be missing
             ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Login successful, but user role is undefined.")),
            );
            return;
          }

          final inchargeName = _extractInchargeName(role);

          if (role == "student") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StudentPage()),
            );
          } else if (inchargeName != null) {
            // --- CATCH ALL INCHARGE ROLES HERE (including old and new ones) ---

            // Check for existing hardcoded routes first (Sports, IOT, DNP)
            if (role == "SportsIncharge") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const Sportsincharge()),
              );
            } else if (role == "IotIncharge") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const IotIncharge()),
              );
            } else if (role == "DnpIncharge") {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DnpIncharge()),
              );
            } 
            // New dynamic lab roles get routed to the generic page
            else {
              // The inchargeName is the name of the lab (e.g., 'GraphicsLab'). 
              // We need to fetch the collection name from the 'labs' metadata collection.
              
              final labMetadataDoc = await FirebaseFirestore.instance
                  .collection('labs')
                  .doc(inchargeName.toLowerCase()) // Match the ID used in adminpage.dart
                  .get();

              if (labMetadataDoc.exists) {
                final collectionName = labMetadataDoc.get('collection_name') as String;
                
                // IMPORTANT: You need to ensure GenericInchargePage exists and handles the logic
                // For this step, we will use a temporary placeholder widget 
                // until you create the actual GenericInchargePage.
                // Replace Placeholder() with GenericInchargePage(...) once created.
                
                // You should route to your generic Incharge dashboard here.
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => GenericInchargePage(
                    labName: inchargeName,
                    collectionName: collectionName,
                  )),
                );

              } else {
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: Lab metadata not found for role $role")),
                 );
                 // Fallback: send them to Admin or Student page if lookup fails
                 Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StudentPage()));
              }
            }
          } 
          else if (role == "Admin") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const adminPage()),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("User document missing. Check Firestore setup.")),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      final snackBar =
          SnackBar(content: Text(e.message ?? "An error occurred"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An unexpected error occurred: $e")),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/WhatsApp Image 2025-10-05 at 23.03.34_e30ecfe5.jpg',
                height: 200,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  hintText: "Email",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  hintText: "Password",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: loginWithEmailAndPassword,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text("Login"),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter your email first")),
                    );
                    return;
                  }
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Password reset email sent")),
                    );
                  } on FirebaseAuthException catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message ?? "Failed to send reset email")),
                    );
                  }
                },
                child: const Text("Forgot/Change Password?"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
