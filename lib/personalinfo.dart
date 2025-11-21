import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Personalinfo extends StatelessWidget {
  const Personalinfo({super.key});
  // void getinfo() async{
  //   await FirebaseFirestore.instance.collection();
  // };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Personal Info"),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(
              1.0,
            ), // height of the black line
            child: Container(color: Colors.black, height: 1.0),
          ),
      ),
      body: Column(
        children: [

        ],
      ),
    );
  }
}