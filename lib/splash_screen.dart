import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iiitnr/GenericInchargePage.dart';
import 'package:iiitnr/HomePage.dart';
import 'package:iiitnr/StudentPage.dart';
import 'package:iiitnr/adminpage.dart'; // Add this import for admin navigation

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for splash screen display
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Check Firebase auth state (persistence handles all roles automatically)
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(user.uid)
            .get();
        if (!mounted) return;

        if (userDoc.exists) {
          final role = userDoc['role'] as String? ?? '';
          
          if (role == 'student') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StudentPage()),
            );
          } else if (role == 'Admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const adminPage()),
            );
          } else {
            // Incharge/LabIncharge/SportsIncharge - all non-student roles
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => LabIncharge(role: role), // Update constructor if needed
              ),
            );
          }
          return;
        }
      } catch (e) {
        // Firestore error - still go to HomePage for manual login
      }
    }
    
    // No user, invalid role, or error: go to login page
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/WhatsApp Image 2025-10-05 at 23.03.34_e30ecfe5.jpg',
          fit: BoxFit.contain,
          height: MediaQuery.of(context).size.height * 0.8,
          width: MediaQuery.of(context).size.width * 0.9,
        ),
      ),
    );
  }
}
