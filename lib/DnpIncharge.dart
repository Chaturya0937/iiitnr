import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iiitnr/LabInchargeScanner.dart';
import 'package:iiitnr/main.dart';
import 'package:iiitnr/HomePage.dart';

class DnpIncharge extends StatefulWidget {
  const DnpIncharge({super.key});

  @override
  State<DnpIncharge> createState() => _DnpInchargeState();
}

class _DnpInchargeState extends State<DnpIncharge> {
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  void _showAddDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController countController = TextEditingController();

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameController,
                    decoration: const InputDecoration(hintText: "Name")),
                const SizedBox(height: 16),
                TextField(
                    controller: countController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: "Count")),
                const SizedBox(height: 16),
                ElevatedButton(
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final count = int.tryParse(countController.text.trim()) ?? 0;
                      if (name.isNotEmpty && count > 0) {
                        await FirebaseFirestore.instance.collection('Dnpequipment').add(
                          {"Name": name, "count": count},
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Add")),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DNP Lab Equipment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
          ),
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: BackgroundImageWrapper(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('Dnpequipment').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No equipments found.'));
                  }
                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      final name = doc['Name'];
                      final count = doc['count'];
                      return ListTile(
                        title: Text('$name : $count'),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: count > 0
                                  ? () {
                                      doc.reference.update({'count': count - 1});
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                doc.reference.update({'count': count + 1});
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                doc.reference.delete();
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LabInchargeScannerPage(scannerPermission: 'Lab')),
                  );
                },
                child: const Text('Scan QR Code'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton(
                onPressed: _showAddDialog,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

