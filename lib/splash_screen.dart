import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iiitnr/HomePage.dart';
import 'package:iiitnr/StudentPage.dart';
import 'package:iiitnr/sportsincharge.dart';
import 'package:iiitnr/IotIncharge.dart';
import 'package:iiitnr/DnpIncharge.dart';

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

    // Check if user is already authenticated
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is logged in, check their role and navigate accordingly
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection("Users")
            .doc(user.uid)
            .get();

        if (userDoc.exists && mounted) {
          final role = userDoc["role"];
          if (role == "student") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const StudentPage()),
            );
          } else if (role == "SportsIncharge") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Sportsincharge()),
            );
          } else if (role == "LabIncharge") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const IotIncharge()),
            );
          } else if (role == "DnpIncharge") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DnpIncharge()),
            );
          } else {
            // Unknown role, go to login
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }
        } else if (mounted) {
          // User doc doesn't exist, go to login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } catch (e) {
        // Error checking user, go to login
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      }
    } else {
      // No user logged in, go to login page
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/WhatsApp Image 2025-10-05 at 23.03.34_e30ecfe5.jpg',
          fit: BoxFit.contain,
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
        ),
      ),
    );
  }
}
