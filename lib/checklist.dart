import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iiitnr/main.dart';

class ItemChecklistPage extends StatefulWidget {
  final List<Map<String, dynamic>> data;

  const ItemChecklistPage({super.key, required this.data});

  @override
  State<ItemChecklistPage> createState() => _ItemChecklistPageState();
}

class _ItemChecklistPageState extends State<ItemChecklistPage> {
  late List<Map<String, dynamic>> data;
  final Map<String, bool> _selectedItems = {};

  @override
  void initState() {
    super.initState();
    data = List.from(widget.data);
    // Initialize selected items map
    for (var item in data) {
      _selectedItems[item['id']] = item['status'] ?? false;
    }
  }

  Future<void> _updateStatus(String docId, bool status) async {
    await FirebaseFirestore.instance.collection('Requests').doc(docId).update({
      'status': status,
    });
  }

  Future<void> _updateSportsCount(String equipment, int count) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('sportsequipment')
        .where("Name", isEqualTo: equipment)
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.update({'count': FieldValue.increment(-count)});
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
                        final bool isApproved = _selectedItems[itemId] ?? false;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          child: ListTile(
                            leading: isApproved
                                ? const Icon(Icons.check_circle, color: Colors.green)
                                : Checkbox(
                                    value: false,
                                    onChanged: (value) async {
                                      if (value != null && value) {
                                        setState(() {
                                          _selectedItems[itemId] = true;
                                          request['status'] = true;
                                        });
                                        await _updateSportsCount(
                                            request["Name"], request["count"]);
                                      }
                                    },
                                  ),
                            title: Text("${request["Name"]} : ${request["count"]}"),
                            trailing: isApproved
                                ? IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('Requests')
                                          .doc(itemId)
                                          .delete();
                                      setState(() {
                                        data.removeAt(index);
                                        _selectedItems.remove(itemId);
                                      });
                                      if (data.isEmpty && mounted) {
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
                          bool status = _selectedItems[itemId] ?? false;
                          await _updateStatus(itemId, status);
                        }
                        if (mounted) Navigator.of(context).pop();
                      },
                      child: const Text('Approve'),
                    ),
                  )
                ],
              ),
      ),
    );
  }
}
