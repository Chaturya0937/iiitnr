import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iiitnr/labqr.dart';
import 'package:iiitnr/main.dart';

class LabRequests extends StatefulWidget {
  const LabRequests({super.key});

  @override
  State<LabRequests> createState() => _LabRequestsState();
}

class _LabRequestsState extends State<LabRequests> {
  User? user = FirebaseAuth.instance.currentUser;

  Future<List<QueryDocumentSnapshot>> _fetchBatches(String type) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("batchid")
        .where('type', isEqualTo: type)
        .get();
    return snapshot.docs;
  }

  void _openBatch(String batchId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Labqr(batchid: batchId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lab Requests"),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0), // height of the black line
          child: Container(color: Colors.black, height: 1.0),
        ),
      ),
      body: BackgroundImageWrapper(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'IOT Equipment Requests:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 300,
                  child: FutureBuilder<List<QueryDocumentSnapshot>>(
                    future: _fetchBatches('IOT'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text("There are no requests"),
                        );
                      }
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          var data =
                              snapshot.data![index].data()
                                  as Map<String, dynamic>;
                          Timestamp timestamp = data['time'];
                          DateTime date = timestamp.toDate();
                          String batchId = date.toString();
                          return Card(
                            child: ListTile(
                              title: Text('Batch ID: $batchId'),
                              onTap: (){
                                batchId = snapshot.data![index].id;
                                _openBatch(batchId);
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'DNP Equipment Requests:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: 300,
                  child: FutureBuilder<List<QueryDocumentSnapshot>>(
                    future: _fetchBatches('DNP'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text("There are no requests"),
                        );
                      }
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          var data =
                              snapshot.data![index].data()
                                  as Map<String, dynamic>;
                          Timestamp timestamp = data['time'];
                          DateTime date = timestamp.toDate();
                          String batchId = date.toString();
                          return Card(
                            child: ListTile(
                              title: Text('Batch ID: $batchId'),
                              onTap: () {
                                batchId = snapshot.data![index].id;
                                _openBatch(batchId);
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
