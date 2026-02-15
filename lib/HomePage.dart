import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iiitnr/GenericInchargePage.dart';
import 'package:iiitnr/StudentPage.dart';
import 'package:iiitnr/adminpage.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

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
          final role = userDoc["role"];
          if (role == "student") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StudentPage()),
            );
          }else if (role == "Admin") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const adminPage()),
            );
          }
          else{
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) =>  LabIncharge(role: role,)),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      final snackBar =
          SnackBar(content: Text(e.message ?? "An error occurred"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
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
              SizedBox(height: 32),
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
