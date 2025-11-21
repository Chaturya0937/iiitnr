import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iiitnr/Dnpequipment.dart';
import 'package:iiitnr/HomePage.dart';
import 'package:iiitnr/Iotequipment.dart';
import 'package:iiitnr/RequestNavigationPage%20.dart';
import 'package:iiitnr/personalinfo.dart';
import 'package:iiitnr/sportsequipment.dart';

class StudentPage extends StatelessWidget {
  const StudentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),

      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0), // optional padding for alignment
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Personalinfo()),
              );
            },
            child: CircleAvatar(
              radius: 15,
              backgroundColor: const Color.fromARGB(255, 91, 169, 237),
              child: Icon(Icons.person, size: 25, color: Colors.white),
            ),
          ),
        ),
        title: const Text("Welcome"),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // After logout, redirect to login page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0), // height of the black line
          child: Container(color: Colors.black, height: 1.0),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset(
              "assets/WhatsApp Image 2025-10-05 at 23.03.34_e30ecfe5.jpg",
              width: MediaQuery.of(context).size.width * 0.7,
            ),
            SizedBox(height: 16.0,),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LabsPage(),
                        ),
                      );
                    },
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        image: DecorationImage(
                          image: AssetImage("assets/lab.png"),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Column(
                          children: [
                            Spacer(flex: 2),
                            Text(
                              "Lab",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Spacer(flex: 1),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const Sportsequipment(),
                        ),
                      );
                    },
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        image: DecorationImage(
                          image: AssetImage(
                            "assets/394a8514c21be4c0fc80e3d2a9879019.jpg",
                          ),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "Sports",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 8.0),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RequestNavigationPage(),
                    ),
                  );
                },
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      27,
                      178,
                      242,
                    ).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "Requets/Accepted Equipment",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}

class LabsPage extends StatelessWidget {
  const LabsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Labs"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0), // height of the black line
          child: Container(color: Colors.black, height: 1.0),
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text("IOT"),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const Iotequipment()),
              );
            },
          ),
          ListTile(
            title: const Text("DNP"),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const Dnpequipment()),
              );
            },
          ),
          ListTile(
            title: const Text("Test 1"),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const Placeholder()),
              );
            },
          ),
          ListTile(
            title: const Text("Test 2"),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const Placeholder()),
              );
            },
          ),
        ],
      ),
    );
  }
}
