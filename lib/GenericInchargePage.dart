import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iiitnr/HomePage.dart';
import 'package:iiitnr/personalinfo.dart';
import 'package:iiitnr/Inchargescanner.dart'; // To handle scanning for item checkout
import 'package:iiitnr/labrequests.dart'; // To manage requests from students

class GenericInchargePage extends StatelessWidget {
  // These parameters are passed from HomePage.dart login
  final String labName;
  final String collectionName; // e.g., 'graphicslab_equipment'
  
  const GenericInchargePage({
    super.key,
    required this.labName,
    required this.collectionName,
  });

  // Utility to convert the collection name to the required scanner permission format
  String get scannerPermission {
    // We assume the collection name is in the format 'labname_equipment'
    // We extract 'labname' and capitalize it to match the role structure (e.g. GraphicsLab)
    return labName;
  }

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
        title: Text("$labName In-Charge Portal"),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.black, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. SCANNER FOR ISSUING/RETURNING EQUIPMENT ---
            DashboardCard(
              title: "Scan & Process Equipment",
              subtitle: "Issue or log return of requested items.",
              icon: Icons.qr_code_scanner,
              color: Colors.blue.shade700,
              onTap: () {
                // Navigate to the scanner page, passing the required permission check.
                // This uses the existing InchargeScanner.dart logic.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InchargeScannerPage(
                      scannerPermission: scannerPermission, 
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),

            // --- 2. MANAGE STUDENT REQUESTS ---
            DashboardCard(
              title: "View Pending Requests",
              subtitle: "Approve or reject equipment loan requests.",
              icon: Icons.list_alt,
              color: Colors.orange.shade700,
              onTap: () {
                // IMPORTANT: You need to adapt labrequests.dart to use collectionName
                // If labrequests.dart handles both sports and lab requests, 
                // ensure it has a way to distinguish, likely by passing collectionName
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LabRequests(
                      // Pass the collection where students submit requests
                      collectionName: collectionName, 
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),

            // --- 3. ADD NEW EQUIPMENT TO LAB INVENTORY ---
            DashboardCard(
              title: "Manage Inventory",
              subtitle: "Add new equipment types or update stock levels.",
              icon: Icons.inventory_2,
              color: Colors.green.shade700,
              onTap: () {
                // This is a placeholder. You need to build a form page 
                // that inserts/updates documents in the 'collectionName' (e.g., 'graphicslab_equipment')
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Inventory Management"),
                    content: Text("Future integration will allow adding/editing items in the collection: $collectionName"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("OK"),
                      )
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 30),
            // Displaying the dynamic collection name for transparency/debugging
            Center(
              child: Text(
                "Managing Firestore Collection: $collectionName",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// A reusable widget for the dashboard tiles
class DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
