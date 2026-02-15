import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:iiitnr/GenericLabEquipmentPage.dart';
import 'package:iiitnr/HomePage.dart';
import 'package:iiitnr/ReturnPage.dart'; // New Import
import 'package:iiitnr/personalinfo.dart';
import 'package:iiitnr/requestlist.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  String searchQuery = "";

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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search equipment (e.g. Bat, Arduino...)",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          Expanded(
            child: searchQuery.isEmpty
                ? _buildMainDashboard(context)
                : _buildGlobalSearchView(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainDashboard(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // NEW FEATURE: Return Equipment Button
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReturnEquipmentPage(),
                  ),
                );
              },
              icon: const Icon(Icons.assignment_return_outlined),
              label: const Text("Return Borrowed Equipment"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

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
                  MaterialPageRoute(builder: (context) => const LabPage()),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  image: const DecorationImage(
                    image: AssetImage("assets/lab.png"),
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
                      color: Colors.black,
                      shadows: [Shadow(blurRadius: 4, color: Colors.white)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          SizedBox(
            height: 150,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GenericLabEquipmentPage(
                      collectionName: 'sportsequipment',
                      labName: 'sports',
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
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
                      color: Colors.white,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalSearchView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('equipment').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        List<Map<String, dynamic>> allMatches = [];
        for (var doc in snapshot.data!.docs) {
          String labName = doc.id.replaceAll('equipment', '').toUpperCase();
          List<dynamic> items = doc['equipment'] ?? [];
          for (var item in items) {
            String name = item['Name'].toString().toLowerCase();
            if (name.contains(searchQuery)) {
              allMatches.add({
                'name': item['Name'],
                'count': item['count'],
                'location': labName,
                'collection': doc.id,
              });
            }
          }
        }

        if (allMatches.isEmpty)
          return const Center(child: Text("No matches found."));

        return ListView.builder(
          itemCount: allMatches.length,
          itemBuilder: (context, index) {
            final item = allMatches[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.inventory_2, color: Colors.blue),
                title: Text(item['name']),
                subtitle: Text(
                  "Available: ${item['count']} | Lab: ${item['location']}",
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GenericLabEquipmentPage(
                        labName: item['location'],
                        collectionName: item['collection'],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
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
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(title: const Text("Lab Equipment")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('labs').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final labDocs = snapshot.data!.docs;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: labDocs.length,
                  itemBuilder: (context, index) {
                    final lab = labDocs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: ListTile(
                        title: Text(lab['name'] ?? 'Unnamed Lab'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GenericLabEquipmentPage(
                                labName: lab['name'],
                                collectionName: lab['collection_name'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.list_alt),
                  label: const Text("My Requests"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StudentRequestListPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
