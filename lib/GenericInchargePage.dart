import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:iiitnr/AdminAnalyticsPage.dart'; // New Import
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

  Future<void> _handleBulkUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) return;

      final picked = result.files.first;
      List<List<dynamic>> rows = [];

      if (kIsWeb) {
        final bytes = picked.bytes;
        if (bytes == null) return;
        final csvString = utf8.decode(bytes);
        rows = const CsvToListConverter().convert(csvString);
      } else {
        final file = File(picked.path!);
        final input = file.openRead();
        rows = await input
            .transform(utf8.decoder)
            .transform(const CsvToListConverter())
            .toList();
      }

      if (rows.isEmpty) return;

      final List<Map<String, dynamic>> newItems = [];
      int addedCount = 0;

      for (int i = 0; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 2) continue;

        final String identifier = row[0].toString().trim();
        final dynamic secondValue = row[1];

        if (identifier.isNotEmpty) {
          // ADMIN ROLE: Bulk Student Import with Trust Score Initialization
          if (widget.role.toLowerCase() == 'admin') {
            newItems.add({
              'Email': identifier,
              'Name': secondValue.toString().trim(),
              'trust_score': 0, // Initializing every student with 0
              'role': 'Student',
            });
          } else {
            // OTHER ROLES: Standard Equipment Upload
            final int eqCount = int.tryParse(secondValue.toString().trim()) ?? 0;
            if (eqCount > 0) {
              newItems.add({'Name': identifier, 'count': eqCount});
            }
          }
          addedCount++;
        }
      }

      if (newItems.isEmpty) return;

      if (widget.role.toLowerCase() == 'admin') {
        final batch = FirebaseFirestore.instance.batch();
        for (var student in newItems) {
          final docRef = FirebaseFirestore.instance.collection('users').doc(student['Email']);
          batch.set(docRef, student, SetOptions(merge: true));
        }
        await batch.commit();
      } else {
        await FirebaseFirestore.instance
            .collection('equipment')
            .doc('${widget.role}equipment')
            .set({
          'equipment': FieldValue.arrayUnion(newItems),
        }, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully processed $addedCount items.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
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
                decoration: const InputDecoration(hintText: 'Name/Email'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: countController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Count/Initial Score'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final val = int.tryParse(countController.text.trim()) ?? 0;
                  if (name.isNotEmpty) {
                    if (widget.role.toLowerCase() == 'admin') {
                      await FirebaseFirestore.instance.collection('users').doc(name).set({
                        'Email': name,
                        'trust_score': val,
                        'role': 'Student',
                      }, SetOptions(merge: true));
                    } else {
                      await FirebaseFirestore.instance
                          .collection('equipment')
                          .doc('${widget.role}equipment')
                          .set({
                        'equipment': FieldValue.arrayUnion([
                          {'Name': name, 'count': val}
                        ])
                      }, SetOptions(merge: true));
                    }
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
        title: Text('${widget.role} Management'),
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
              child: widget.role.toLowerCase() == 'admin'
                  ? _buildUserList()
                  : _buildEquipmentList(),
            ),
            
            // NEW FEATURE: Analytics Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminAnalyticsPage()),
                  );
                },
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('View Data Analytics'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _handleBulkUpload,
                icon: const Icon(Icons.upload_file),
                label: Text(widget.role.toLowerCase() == 'admin' 
                    ? 'Import Students (CSV)' 
                    : 'Import Equipment (CSV)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),

            if (widget.role.toLowerCase() != 'admin')
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
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Student').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['Email'] ?? 'Unknown Student'),
              subtitle: Text('Trust Score: ${data['trust_score'] ?? 0}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => docs[index].reference.delete(),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEquipmentList() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('equipment')
          .doc('${widget.role}equipment')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('No equipments found.'));
        }
        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final List<dynamic> equipment = data['equipment'] ?? [];
        return ListView.builder(
          itemCount: equipment.length,
          itemBuilder: (context, index) {
            final item = equipment[index] as Map<String, dynamic>;
            final String name = item['Name']?.toString() ?? '';
            final int count = (item['count']
