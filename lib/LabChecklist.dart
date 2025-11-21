import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iiitnr/main.dart';

class LabChecklistPage extends StatefulWidget {
  final List<Map<String, dynamic>> data;

  const LabChecklistPage({super.key, required this.data});

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
    // Initialize selected items map
    for (var item in data) {
      selectedItems[item['id']] = item['status'] ?? false;
    }
  }

  Future<void> _updateStatus(String docId, bool status) async {
    await FirebaseFirestore.instance
        .collection('LabRequests')
        .doc(docId)
        .update({'status': status});
  }

  Future<void> _updateLabCount(
    String equipment,
    int count,
    String equipmentType,
  ) async {
    String collectionName;
    if (equipmentType == 'IOT') {
      collectionName = 'Iotequipment';
    } else if (equipmentType == 'DNP') {
      collectionName = 'Dnpequipment';
    } else {
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection(collectionName)
        .where("Name", isEqualTo: equipment)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'count': FieldValue.increment(-count)});
    }
  }

  Future<void> _afterUpdateLabCount(
    String equipment,
    int count,
    String equipmentType,
  ) async {
    String collectionName;
    if (equipmentType == 'IOT') {
      collectionName = 'Iotequipment';
    } else if (equipmentType == 'DNP') {
      collectionName = 'Dnpequipment';
    } else {
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection(collectionName)
        .where("Name", isEqualTo: equipment)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'count': FieldValue.increment(count)});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Checklist')),
      body: BackgroundImageWrapper(
        child: data.isEmpty
            ? const Center(child: Text('No items available'))
            : Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "Student Email: ${data.first['Email']}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final request = data[index];
                        final String itemId = request['id'];
                        bool isChecked = selectedItems[itemId] ?? false;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: ListTile(
                            leading: isChecked
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : Checkbox(
                                    value: isChecked,
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          selectedItems[itemId] = value;
                                        });
                                      }
                                    },
                                  ),
                            title: Text(
                              "${request["Name"]} : ${request["count"]}",
                            ),
                            trailing: isChecked
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      var docSnapshot = await FirebaseFirestore
                                          .instance
                                          .collection('LabRequests')
                                          .doc(itemId)
                                          .get();
                                      String equipmentType =
                                          request['type'] ?? '';
                                      await _afterUpdateLabCount(
                                          request["Name"],
                                          request["count"],
                                          equipmentType);
                                      var id = docSnapshot.data()!["batchid"];
                                      await FirebaseFirestore.instance
                                          .collection('LabRequests')
                                          .doc(itemId)
                                          .delete();
                                      setState(() {
                                        data.removeAt(index);
                                        selectedItems.remove(itemId);
                                      });
                                      if (data.isEmpty && mounted) {
                                        await FirebaseFirestore.instance
                                            .collection('batchid')
                                            .doc(id)
                                            .delete();
                                        Navigator.of(context).pop();
                                      }
                                    },
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        for (var request in data) {
                          String itemId = request['id'];
                          bool status = selectedItems[itemId] ?? false;
                          await _updateStatus(itemId, status);
                          if (status) {
                            String equipmentType = request['type'] ?? '';
                            await _updateLabCount(
                              request["Name"],
                              request["count"],
                              equipmentType,
                            );
                          }
                        }
                        if (mounted) Navigator.of(context).pop();
                      },
                      child: const Text('Approve'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
