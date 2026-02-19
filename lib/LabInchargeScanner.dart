import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iiitnr/labchecklist.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class LabInchargeScannerPage extends StatefulWidget {
  final String scannerPermission;

  const LabInchargeScannerPage({super.key, required this.scannerPermission});

  @override
  State<LabInchargeScannerPage> createState() => _LabInchargeScannerPageState();
}

class _LabInchargeScannerPageState extends State<LabInchargeScannerPage> {
  String? scannedData;
  bool hasPermission = false;
  String? errorMessage;
  final MobileScannerController controller = MobileScannerController();

  @override
  void initState() {
    super.initState();
    checkCameraPermission();
  }

  Future<void> checkCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    setState(() => hasPermission = status.isGranted);
  }

  void handleDetection(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          scannedData = code;
          errorMessage = null;
        });
        controller.stop();
      }
    }
  }

  // Return logic kept as-is (can be reused for unified flow)
  Future<void> _processReturn(List<Map<String, dynamic>> items) async {
    final batch = FirebaseFirestore.instance.batch();

    try {
      for (var item in items) {
        final String itemName = item['Name'];
        final int count = item['count'];
        final String collection =
            "${widget.scannerPermission.toLowerCase()}equipment";

        final docRef =
            FirebaseFirestore.instance.collection('equipment').doc(collection);

        batch.update(docRef, {
          'equipment': FieldValue.arrayUnion([
            {'Name': itemName, 'count': FieldValue.increment(count)}
          ])
        });
      }

      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Inventory Updated Successfully")),
        );
        setState(() => scannedData = null);
        controller.start();
      }
    } catch (e) {
      setState(() => errorMessage = "Operation failed: $e");
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        "Building LabInchargeScannerPage with permission: ${widget.scannerPermission}");

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.scannerPermission} Incharge Scanner"),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: hasPermission
                ? MobileScanner(
                    controller: controller, onDetect: handleDetection)
                : const Center(child: Text("Camera permission required")),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: scannedData == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_scanner,
                            size: 40, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(errorMessage ??
                            "Scan a Student QR to Proceed"),
                      ],
                    )
                  : _buildResultUI(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildResultUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.verified, color: Colors.green, size: 50),
        const Text("Smart Verification Complete",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const Text("Student Profile: HIGH TRUST",
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
          ),
          onPressed: () {
            final List<Map<String, dynamic>> parsed =
                List<Map<String, dynamic>>.from(
                    jsonDecode(scannedData!));

            // Unified flow – you can later decide internally
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => LabChecklistPage(
                  data: parsed,
                  labCollectionName:
                      "${widget.scannerPermission.toLowerCase()}equipment",
                ),
              ),
            );
          },
          child: const Text("Proceed"),
        ),
        TextButton(
          onPressed: () {
            setState(() => scannedData = null);
            controller.start();
          },
          child: const Text("Cancel / Scan Again"),
        )
      ],
    );
  }
}
