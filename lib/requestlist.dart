import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iiitnr/Requests.dart';
import 'package:iiitnr/main.dart';

class Requestlist extends StatelessWidget {
  const Requestlist({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Request List",
          style: TextStyle(color: Colors.black),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0), // height of the black line
          child: Container(color: Colors.black, height: 1.0),
        ),
      ),
      
      body: BackgroundImageWrapper(
        child: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('batchid')
              .where('type', isEqualTo: 'Sports')
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No requests found",
                  style: TextStyle(color: Colors.black),
                ),
              );
            }
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var data =
                    snapshot.data!.docs[index].data() as Map<String, dynamic>;
                Timestamp timestamp = data['time'];
                DateTime date = timestamp.toDate();
                String batchId = date.toString();
                return Card(
                  child: ListTile(
                    title: Text(
                      "Request ID: $batchId",
                      style: const TextStyle(fontSize: 18),
                    ),
                    onTap: () {
                      batchId = snapshot.data!.docs[index].id;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              StudentRespectiveRequests(batchid: batchId),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
