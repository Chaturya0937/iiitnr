import 'package:flutter/material.dart';
import 'package:iiitnr/labrequests.dart';
import 'package:iiitnr/main.dart';
import 'package:iiitnr/requestlist.dart';

class RequestNavigationPage extends StatelessWidget {
  const RequestNavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Requested/Accepted Equipment'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(
            1.0,
          ), // height of the black line
          child: Container(color: Colors.black, height: 1.0),
        ),
      ),
      body: BackgroundImageWrapper(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(flex: 2,),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LabRequests()),
                  );
                },
                child: Card(
                  elevation: 5,
                  color: const Color.fromARGB(255, 152, 230, 254),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    height: 150,
                    child: Center(
                      child: Text(
                        'Lab',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Requestlist()),
                  );
                },
                child: Card(
                  elevation: 5,
                  color: const Color.fromARGB(255, 152, 230, 254),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    height: 150,
                    child: Center(
                      child: Text(
                        'Sports',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Spacer(flex: 1,),
            ],
          ),
        ),
      ),
    );
  }
}
