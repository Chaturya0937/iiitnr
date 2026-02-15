import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:iiitnr/HomePage.dart';
import 'package:iiitnr/LabInchargeScanner.dart';
import 'package:iiitnr/main.dart';

class LabIncharge extends StatefulWidget {
  final String role;
  const LabIncharge({super.key, required this.role});

  @override
  State<LabIncharge> createState() => _LabInchargeState();
}

class _LabInchargeState extends State<LabIncharge> {
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  // SIMPLE: pick file and parse as CSV (no extension check)
  Future<void> _handleBulkUpload() async {
    try {
      // 1. Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) return;

      final picked = result.files.first;
      final name = picked.name.toLowerCase();
      final path = picked.path ?? '';

      debugPrint('Picked file name: $name');
      debugPrint('Picked file path: $path');

      // 2. Read CSV into rows
      List<List<dynamic>> rows = [];

      if (kIsWeb) {
        final bytes = picked.bytes;
        if (bytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not read file bytes.')),
          );
          return;
        }
        final csvString = utf8.decode(bytes);
        rows = const CsvToListConverter().convert(csvString);
      } else {
        if (picked.path == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File path is null.')),
          );
          return;
        }
        final file = File(picked.path!);
        final input = file.openRead();
        rows = await input
            .transform(utf8.decoder)
            .transform(const CsvToListConverter())
            .toList();
      }

      debugPrint('CSV rows: $rows');

      if (rows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File is empty or invalid CSV.')),
        );
        return;
      }

      // 3. Convert rows -> equipment list (Name, Count)
      final List<Map<String, dynamic>> newEquipment = [];
      int addedCount = 0;

      // Your file has NO header, so start at 0
      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 2) continue;

        final String eqName = row[0].toString().trim();
        final int eqCount = int.tryParse(row[1].toString().trim()) ?? 0;

        if (eqName.isNotEmpty && eqCount > 0) {
          newEquipment.add({'Name': eqName, 'count': eqCount});
          addedCount++;
        }
      }

      if (newEquipment.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid items found in CSV.')),
        );
        return;
      }

      // 4. Save to Firestore
      await FirebaseFirestore.instance
          .collection('equipment')
          .doc('${widget.role}equipment')
          .set({
        'equipment': FieldValue.arrayUnion(newEquipment),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully imported $addedCount items.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final countController = TextEditingController();

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
                decoration: const InputDecoration(hintText: 'Name'),
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
                  final count =
                      int.tryParse(countController.text.trim()) ?? 0;
                  if (name.isNotEmpty && count > 0) {
                    await FirebaseFirestore.instance
                        .collection('equipment')
                        .doc('${widget.role}equipment')
                        .set({
                      'equipment': FieldValue.arrayUnion([
                        {'Name': name, 'count': count}
                      ])
                    }, SetOptions(merge: true));
                    if (mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role} Lab Equipment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
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
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('equipment')
                    .doc('${widget.role}equipment')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(
                      child: Text('No equipments found.'),
                    );
                  }

                  final data = snapshot.data!.data()
                          as Map<String, dynamic>? ??
                      {};
                  final List<dynamic> equipment =
                      data['equipment'] ?? [];

                  if (equipment.isEmpty) {
                    return const Center(
                      child: Text('No equipments found.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: equipment.length,
                    itemBuilder: (context, index) {
                      final item = equipment[index]
                              as Map<String, dynamic>? ??
                          {};
                      final String name =
                          item['Name']?.toString() ?? '';
                      final int count =
                          (item['count'] ?? 0) as int;

                      return ListTile(
                        title: Text('$name : $count'),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: count > 0
                                  ? () async {
                                      equipment[index]['count'] =
                                          count - 1;
                                      await snapshot
                                          .data!.reference
                                          .update({
                                        'equipment': equipment,
                                      });
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () async {
                                equipment[index]['count'] =
                                    count + 1;
                                await snapshot.data!.reference
                                    .update({
                                  'equipment': equipment,
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                equipment.removeAt(index);
                                await snapshot.data!.reference
                                    .update({
                                  'equipment': equipment,
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Simple CSV import button
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _handleBulkUpload,
                icon: const Icon(Icons.upload_file),
                label: const Text('Import Equipment (CSV)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: ElevatedButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Accepted(role: widget.role),
        ),
      );
    },
    icon: const Icon(Icons.check_circle_outline),
    label: const Text('View Accepted Equipment'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
  ),
),

            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LabInchargeScannerPage(
                        scannerPermission: widget.role,
                      ),
                    ),
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


class Accepted extends StatefulWidget {
  final String role;
  const Accepted({super.key,required this.role});

  @override
  State<Accepted> createState() => _AcceptedState();
}

class _AcceptedState extends State<Accepted> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Accepted'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body:     BackgroundImageWrapper(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('Requests')
              .where('status', isEqualTo: true)
              .where('equipment_collection', isEqualTo: '${widget.role}equipment')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No accepted equipment yet.'));
            }
        
            final docs = snapshot.data!.docs;
        
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final email = data['Email']?.toString() ?? 'Unknown';
                final eqName = data['Name']?.toString() ?? 'Unknown';
                final count = data['count'] ?? 0;
        
                return ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text('$eqName  (x$count)'),
                  subtitle: Text(email),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

