import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iiitnr/main.dart';
import 'package:iiitnr/labqr.dart';

class Dnpequipment extends StatefulWidget {
  const Dnpequipment({super.key});

  @override
  State<Dnpequipment> createState() => _DnpequipmentState();
}

class _DnpequipmentState extends State<Dnpequipment> {
  final Map<String, bool> _selectedItems = {};
  final Map<String, TextEditingController> _requestedItems = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    // Dispose all requested item controllers
    for (var controller in _requestedItems.values) {
      controller.dispose();
    }
    super.dispose();
  }

void _showrequests(BuildContext context) {
  final TextEditingController endDateController = TextEditingController();
  final String startDate = DateTime.now().toLocal().toString().split(' ')[0]; // Today's date

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Start Date: $startDate', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: endDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDate != null) {
                            endDateController.text = pickedDate.toLocal().toString().split(' ')[0];
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
                      String itemName = _requestedItems.keys.elementAt(index);
                      TextEditingController countController = _requestedItems[itemName]!;
                      return ListTile(
                        title: Text(itemName),
                        subtitle: TextField(
                          controller: countController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Enter quantity',
                          ),
                        ),
                      );
                    },
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 253, 232, 255),
                    foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                  ),
                  onPressed: () async {
                    if (endDateController.text.isEmpty) {
                      AlertDialog alert = AlertDialog(
                        title: const Text("Error"),
                        content: const Text("Please enter an end date."),
                        actions: [
                          TextButton(
                            child: const Text("OK"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return alert;
                        },
                      );
                      return;
                    }
                    bool hasError = false;
                    bool addedAnyRequest = false;
                    final itemsToProcess = Map<String, TextEditingController>.from(_requestedItems);
                    String batchId = FirebaseFirestore.instance.collection('LabRequests').doc().id;
                    for (var entry in itemsToProcess.entries) {
                      String itemName = entry.key;
                      String text = entry.value.text;
                      int count = int.tryParse(text) ?? 0;
                      User? user = FirebaseAuth.instance.currentUser;

                      final doc = await FirebaseFirestore.instance
                          .collection('Dnpequipment')
                          .where('Name', isEqualTo: itemName)
                          .get();

                      if (count > 0 && doc.docs.isNotEmpty) {
                        int available = doc.docs.first['count'];

                        if (count <= available) {
                          await FirebaseFirestore.instance.collection('LabRequests').doc().set({
                            'id': user!.uid,
                            'Email': user.email,
                            'Name': itemName,
                            'count': count,
                            'status': false,
                            'batchId': batchId,
                            'type': 'DNP',
                            'startDate': startDate,
                            'endDate': endDateController.text,
                          });

                          addedAnyRequest = true;

                          if (!mounted) return;
                          setState(() {
                            _selectedItems[itemName] = false;
                            final controller = _requestedItems.remove(itemName);
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              controller?.dispose();
                            });
                          });
                        } else {
                          hasError = true;
                          if (!mounted) return;
                          AlertDialog alert = AlertDialog(
                            title: const Text("Error"),
                            content: Text("Requested quantity for $itemName exceeds available stock."),
                            actions: [
                              TextButton(
                                child: const Text("OK"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return alert;
                            },
                          );
                        }
                      }
                    }

                    if (addedAnyRequest && !hasError) {
                      await FirebaseFirestore.instance.collection('batchid').doc(batchId).set({
                        'id': batchId,
                        'time': DateTime.now(),
                        'type': 'DNP',
                      });

                      if (mounted) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => Labqr(batchid: batchId),
                          ),
                        );
                      }
                    } else if (!hasError && mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  child: const Text("Submit Requests"),
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
          title: Text("DNP Equipment"),
          actions: [
            IconButton(
              onPressed: () {
                setState(() {});
              },
              icon: Icon(Icons.refresh),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(1.0), // height of the black line
            child: Container(color: Colors.black, height: 1.0),
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
              FutureBuilder(
                future: FirebaseFirestore.instance
                    .collection("Dnpequipment")
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Align(
                      alignment: Alignment.center,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          "There are no equipments",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }

                  // Filter docs based on search query
                  final filteredDocs = snapshot.data!.docs.where((doc) {
                    if (_searchQuery.isEmpty) return true;
                    final name = doc["Name"].toString().toLowerCase();
                    return name.contains(_searchQuery);
                  }).toList();

                  if (filteredDocs.isEmpty && _searchQuery.isNotEmpty) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          "No equipment found",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }

                  return Expanded(
                    child: ListView.builder(
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final name = doc["Name"];
                        _selectedItems.putIfAbsent(name, () => false);
                        return SizedBox(
                          height: 50,
                          child: Card(
                            child: Align(
                              alignment: Alignment.center,
                              child: CheckboxListTile(
                                value: _selectedItems[name],
                                onChanged: (bool? value) {
                                  setState(() {
                                    _selectedItems[name] = value!;
                                    if (value) {
                                      _requestedItems[name] =
                                          TextEditingController();
                                    } else {
                                      _requestedItems[name]?.dispose();
                                      _requestedItems.remove(name);
                                    }
                                  });
                                },
                                title: Text(
                                  "${doc["Name"]} : ${doc["count"]}",
                                  style: TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 253, 232, 255),
                  foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                ),
                onPressed: () {
                  _showrequests(context);
                },
                child: Text("Request"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
