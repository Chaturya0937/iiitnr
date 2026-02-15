import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iiitnr/Requests.dart';
import 'package:iiitnr/labrequests.dart';
import 'package:iiitnr/main.dart';

class Sportsequipment extends StatefulWidget {
  const Sportsequipment({super.key});

  @override
  State<Sportsequipment> createState() => _SportsequipmentState();
}

class _SportsequipmentState extends State<Sportsequipment> {
  final Map<String, bool> _selectedItems = {};
  final Map<String, TextEditingController> _requestedItems = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    for (final c in _requestedItems.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showRequestsBottomSheet(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final TextEditingController endDateController = TextEditingController();
    final String startDate = DateTime.now().toLocal().toString().split(' ')[0];

    // Build helper map: {itemName: availableCount}
    final Map<String, int> availableMap = {
      for (final d in docs)
        (d.data()['Name'] ?? 'Unknown')
            as String: ((d.data()['count'] ?? 0) is num
            ? (d.data()['count'] as num).toInt()
            : 0),
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lab: Sports',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Start Date: $startDate',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: endDateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'End Date',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          onTap: () async {
                            final DateTime now = DateTime.now();
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: now.add(const Duration(days: 1)),
                              firstDate: now,
                              lastDate: DateTime(2101),
                            );
                            if (picked != null) {
                              endDateController.text = picked
                                  .toLocal()
                                  .toString()
                                  .split(' ')[0];
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: _requestedItems.length,
                      itemBuilder: (context, index) {
                        final itemName = _requestedItems.keys.elementAt(index);
                        final controller = _requestedItems[itemName]!;
                        final available = availableMap[itemName] ?? 0;
                        return ListTile(
                          title: Text(itemName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Available: $available'),
                              TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Enter quantity',
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          253,
                          232,
                          255,
                        ),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        if (endDateController.text.isEmpty) {
                          _showErrorDialog(
                            context,
                            "Please select an end date.",
                          );
                          return;
                        }

                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null || user.email == null) {
                          _showErrorDialog(
                            context,
                            "Authentication error. Please log in again.",
                          );
                          return;
                        }

                        bool hasError = false;
                        bool addedAnyRequest = false;
                        final batchId = FirebaseFirestore.instance
                            .collection('Requests')
                            .doc()
                            .id;

                        final itemsToProcess =
                            Map<String, TextEditingController>.from(
                              _requestedItems,
                            );

                        for (final entry in itemsToProcess.entries) {
                          final itemName = entry.key;
                          final controller = entry.value;
                          final text = controller.text.trim();
                          final int count = int.tryParse(text) ?? 0;
                          final int available = availableMap[itemName] ?? 0;

                          if (count <= 0) {
                            hasError = true;
                            _showErrorDialog(
                              context,
                              "Requested quantity for $itemName must be greater than zero.",
                            );
                            continue;
                          }

                          if (count > available) {
                            hasError = true;
                            _showErrorDialog(
                              context,
                              "Requested quantity for $itemName exceeds available amount ($available).",
                            );
                            continue;
                          }

                          await FirebaseFirestore.instance
                              .collection('Requests')
                              .add({
                                'id': user.uid,
                                'Email': user.email,
                                'Name': itemName,
                                'count': count,
                                'status': false,
                                'batchId': batchId,
                                'startDate': startDate,
                                'endDate': endDateController.text,
                                'equipment_collection': 'sportsequipment',
                                'permission': 'Sports',
                                'createdAt': FieldValue.serverTimestamp(),
                              });

                          addedAnyRequest = true;
                        }

                        if (addedAnyRequest && !hasError) {
                          await FirebaseFirestore.instance
                              .collection('batchid')
                              .doc(batchId)
                              .set({
                                'id': batchId,
                                'time': DateTime.now(),
                                'type': 'Sports',
                                'duedate': DateTime.parse(
                                  endDateController.text,
                                ),
                                'equipment_collection': 'sportsequipment',
                              });

                          if (mounted) {
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    StudentRespectiveRequests(batchid: batchId),
                              ),
                            );
                          }
                        } else if (!hasError && mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text("Submit Requests"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Sports Equipment"),
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
        body: BackgroundImageWrapper(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search equipment...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection("sportsequipment")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("There are no equipments"),
                      );
                    }

                    var docs = snapshot.data!.docs;

                    // Filter by search
                    if (_searchQuery.isNotEmpty) {
                      docs = docs
                          .where(
                            (d) => (d.data()['Name'] ?? '')
                                .toString()
                                .toLowerCase()
                                .contains(_searchQuery),
                          )
                          .toList();
                    }

                    if (docs.isEmpty) {
                      return const Center(child: Text("No equipment found"));
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();
                        final String name = data['Name'] ?? 'Unknown Item';
                        final num rawCount = data['count'] ?? 0;
                        final int count = rawCount.toInt();

                        _selectedItems.putIfAbsent(name, () => false);

                        return SizedBox(
                          height: 60,
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: CheckboxListTile(
                              value: _selectedItems[name],
                              onChanged: (bool? value) {
                                setState(() {
                                  final v = value ?? false;
                                  _selectedItems[name] = v;
                                  if (v) {
                                    _requestedItems[name] =
                                        TextEditingController();
                                  } else {
                                    _requestedItems[name]?.dispose();
                                    _requestedItems.remove(name);
                                  }
                                });
                              },
                              title: Text(
                                "$name : $count",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (_requestedItems.isEmpty) {
                          _showErrorDialog(
                            context,
                            "Please select at least one equipment item.",
                          );
                          return;
                        }

                        // Load current sports equipment for validation
                        try {
                          final snap = await FirebaseFirestore.instance
                              .collection('sportsequipment')
                              .get();

                          final docs = snap.docs;
                          if (!mounted) return;
                          _showRequestsBottomSheet(context, docs);
                        } catch (e) {
                          if (!mounted) return;
                          _showErrorDialog(
                            context,
                            "Failed to load equipment: $e",
                          );
                        }
                      },
                      icon: const Icon(Icons.send),
                      label: const Text("Request Selected Equipment"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        // keep your existing navigation for sports requests
                        // or adapt as needed
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => LabRequests(
                              collectionName: 'sportsequipment', // hard-coded
                              labName: 'Sports', // hard-coded
                            ), // or StudentRespectiveRequests list
                          ),
                        );
                      },
                      icon: const Icon(Icons.list),
                      label: const Text("View Pending/Accepted Requests"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
