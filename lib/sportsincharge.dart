import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iiitnr/HomePage.dart';
import 'package:iiitnr/Inchargescanner.dart';
import 'package:iiitnr/main.dart';

class Sportsincharge extends StatefulWidget {
  const Sportsincharge({super.key});

  @override
  State<Sportsincharge> createState() => _SportsinchargeState();
}

class _SportsinchargeState extends State<Sportsincharge> {
  void _showAddDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController countController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
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
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Equipment Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: countController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Count'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final count = int.tryParse(countController.text.trim()) ?? 0;
                  if (name.isNotEmpty && count > 0) {
                    await FirebaseFirestore.instance
                        .collection('sportsequipment')
                        .add({"Name": name, "count": count});
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sports Equipment'),
        actions: [
          IconButton(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0), // height of the black line
          child: Container(color: Colors.black, height: 1.0),
        ),
      ),
      body: BackgroundImageWrapper(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('sportsequipment')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No equipment found.'));
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
                                      doc.reference.update({
                                        'count': count - 1,
                                      });
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
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  FloatingActionButton(
                    onPressed: _showAddDialog,
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InchargeScannerPage(scannerPermission: 'Sports'),
                        ),
                      );
                    },
                    child: const Text('Scan QR Code'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
