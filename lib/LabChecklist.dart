import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LabChecklistPage extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final String labCollectionName;

  const LabChecklistPage({
    super.key,
    required this.data,
    required this.labCollectionName,
  });

  @override
  State<LabChecklistPage> createState() => _LabChecklistPageState();
}

class _LabChecklistPageState extends State<LabChecklistPage> {
  late List<Map<String, dynamic>> data;
  final Map<String, bool> selectedItems = {};

  @override
  void initState() {
    super.initState();
    data = List.from(widget.data);
    for (var item in data) {
      selectedItems[item['id'] ?? ''] = item['status'] ?? false;
    }
  }

  Future<void> updateStatus(String docId, bool status) async {
    await FirebaseFirestore.instance
        .collection('Requests')
        .doc(docId)
        .update({'status': status});
  }

  /// ISSUE: decrease lab stock by delta when approving a request
  Future<void> updateLabCount(String equipmentName, int delta) async {
    final docRef = FirebaseFirestore.instance
        .collection('equipment')              // top‑level collection
        .doc(widget.labCollectionName);       // e.g. 'Iotequipment'

    final snap = await docRef.get();
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;
    final List<dynamic> equipmentList =
        List<dynamic>.from(data['equipment'] ?? []);

    for (int i = 0; i < equipmentList.length; i++) {
      final item = Map<String, dynamic>.from(equipmentList[i]);
      if (item['Name'] == equipmentName) {
        final currentCount = (item['count'] ?? 0) as int;
        item['count'] = currentCount - delta;   // issuing → stock decreases
        equipmentList[i] = item;
        break;
      }
    }

    await docRef.update({'equipment': equipmentList});
  }

  /// RETURN: increase lab stock by delta when student returns items
  Future<void> updateLabCount_deleted(String equipmentName, int delta) async {
    final docRef = FirebaseFirestore.instance
        .collection('equipment')              // top‑level collection
        .doc(widget.labCollectionName);       // e.g. 'Iotequipment'

    final snap = await docRef.get();
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;
    final List<dynamic> equipmentList =
        List<dynamic>.from(data['equipment'] ?? []);

    for (int i = 0; i < equipmentList.length; i++) {
      final item = Map<String, dynamic>.from(equipmentList[i]);
      if (item['Name'] == equipmentName) {
        final currentCount = (item['count'] ?? 0) as int;
        item['count'] = currentCount + delta;   // returning → stock increases
        equipmentList[i] = item;
        break;
      }
    }

    await docRef.update({'equipment': equipmentList});
  }

  /// Bottom sheet to handle partial (or full) return
  void _showPartialReturnSheet(Map<String, dynamic> item, int index) {
    final TextEditingController controller = TextEditingController();
    final int total = item['count'] as int;
    final String name = item['Name'] as String;
    final String itemId = item['id'] as String;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Return for $name'),
              const SizedBox(height: 8),
              Text('Requested quantity: $total'),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity returned now',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;

                  final int returnedNow = int.tryParse(text) ?? 0;
                  if (returnedNow <= 0 || returnedNow > total) {
                    // You can show a Snackbar here for invalid input
                    return;
                  }

                  // 1) Increase lab stock by returnedNow
                  await updateLabCount_deleted(name, returnedNow);

                  // 2) Optionally track returned quantity in Requests
                  await FirebaseFirestore.instance
                      .collection('Requests')
                      .doc(itemId)
                      .update({
                    'count': FieldValue.increment(-returnedNow),
                  });

                  // 3) If fully returned, delete the request document
                  if (returnedNow == total) {
                    await FirebaseFirestore.instance
                        .collection('Requests')
                        .doc(itemId)
                        .delete();
                    setState(() {
                      data.removeAt(index);
                      selectedItems.remove(itemId);
                    });
                  } else {
                    // Partially returned: update local item count remaining
                    setState(() {
                      item['count'] = total - returnedNow;
                    });
                  }

                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Confirm'),
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
        title: const Text("Item Checklist"),
      ),
      body: data.isEmpty
          ? const Center(child: Text("No items available"))
          : ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                final itemId = item['id'] ?? '';
                final isChecked = selectedItems[itemId] ?? false;

                return Card(
                  child: ListTile(
                    leading: isChecked
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : Checkbox(
                            value: isChecked,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  selectedItems[itemId] = val;
                                });
                              }
                            },
                          ),
                    // Uses Name and count from the request data
                    title: Text(
                      '${item['Name'] ?? 'Unknown'} : ${item['count']}',
                    ),
                    trailing: isChecked
                        ? IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // Instead of always returning full count,
                              // open partial‑return sheet.
                              _showPartialReturnSheet(item, index);
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Approve selected items and decrease lab counts
          for (var entry in selectedItems.entries) {
            await updateStatus(entry.key, entry.value);

            if (entry.value) {
              final item = data.firstWhere(
                (element) => element['id'] == entry.key,
                orElse: () => {},
              );
              if (item.isNotEmpty) {
                final name = item['Name'] as String;
                final int delta = (item['count'] is int)
                    ? item['count'] as int
                    : int.parse(item['count'].toString());
                await updateLabCount(name, delta);
              }
            }
          }
          Navigator.of(context).pop();
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}
