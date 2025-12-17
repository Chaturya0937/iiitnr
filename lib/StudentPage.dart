import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:iiitnr/GenericLabEquipmentPage.dart';
import 'package:iiitnr/HomePage.dart';
import 'package:iiitnr/RequestNavigationPage .dart';
import 'package:iiitnr/personalinfo.dart';
import 'package:iiitnr/sportsequipment.dart';

class StudentPage extends StatelessWidget {
  const StudentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
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
        title: const Text("Welcome"),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: ColoredBox(color: Colors.black, child: SizedBox(height: 1.0)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset(
              "assets/WhatsApp Image 2025-10-05 at 23.03.34_e30ecfe5.jpg",
              width: MediaQuery.of(context).size.width * 0.7,
            ),
            const SizedBox(height: 16.0),
            SizedBox(
              height: 150,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LabPage()
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    image: const DecorationImage(
                      image: AssetImage(
                        "assets/lab.png",
                      ),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "Labs",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 0, 0),
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8.0),

            // ---------- SPORTS (OLD BEHAVIOUR) ----------
            SizedBox(
              height: 150,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GenericLabEquipmentPage(
                        collectionName: 'sportsequipment', // hard-coded
                        labName: 'sports', // hard-coded
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    image: const DecorationImage(
                      image: AssetImage(
                        "assets/394a8514c21be4c0fc80e3d2a9879019.jpg",
                      ),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "Sports",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 255, 255, 255),
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8.0),
          ],
        ),
      ),
    );
  }
}

class LabPage extends StatefulWidget {
  const LabPage({super.key});

  @override
  State<LabPage> createState() => _LabPageState();
}

class _LabPageState extends State<LabPage> {
  @override
  Widget build(BuildContext context) {
    return // ---------- DYNAMIC LABS LIST ----------
    Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: Text("Lab Equipment"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: ColoredBox(
            color: Colors.black,
            child: SizedBox(height: 1.0),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('labs').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading labs: ${snapshot.error}"),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No labs currently registered."));
          }
      
          final labDocs = snapshot.data!.docs;
      
          return ListView.builder(
            itemCount: labDocs.length,
            itemBuilder: (context, index) {
              final lab = labDocs[index];
              final labName = lab['name'] as String? ?? 'Unnamed Lab';
              final collectionName = lab['collection_name'] as String? ?? '';
      
              if (collectionName.isEmpty) {
                return const SizedBox.shrink();
              }
      
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(labName),
                  subtitle: const Text('Tap to view & request equipment'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GenericLabEquipmentPage(
                          labName: labName,
                          collectionName: collectionName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
