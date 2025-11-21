import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:iiitnr/checklist.dart';  // Your item checklist page import
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class InchargeScannerPage extends StatefulWidget {
  // Pass the permission expected by this scanner, e.g. 'DNP', 'Sports'
  final String scannerPermission;
  const InchargeScannerPage({super.key, required this.scannerPermission});

  @override
  State<InchargeScannerPage> createState() => _InchargeScannerPageState();
}

class _InchargeScannerPageState extends State<InchargeScannerPage> {
  String? scannedData;
  bool hasPermission = false;
  String? errorMessage;

  final MobileScannerController controller = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
  }

  Future<void> _checkCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    setState(() {
      hasPermission = status.isGranted;
    });
  }

  void _handleDetection(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue;
      if (code != null && scannedData == null) {
        try {
          final decoded = jsonDecode(code);

          // Expecting a list of maps
          if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
            Map<String, dynamic> firstItem = decoded.first;

            // Extract the permission from the scanned QR data
            String qrPermission = firstItem['permission'] ?? "";

            // Permission check: reject if mismatch
            if (qrPermission != widget.scannerPermission) {
              setState(() {
                errorMessage = "Scan rejected: permission mismatch.";
                scannedData = null;
              });
              return; // Do not proceed
            }

            // Permission matches: accept scan
            setState(() {
              scannedData = code;
              errorMessage = null;
            });
            controller.stop(); // stop scanning

          } else {
            setState(() {
              errorMessage = "Invalid QR structure (expected list of items).";
            });
          }
        } catch (e) {
          setState(() {
            errorMessage = "Invalid QR code format.";
          });
        }
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scanner")),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: hasPermission
                ? MobileScanner(
                    controller: controller,
                    onDetect: _handleDetection,
                  )
                : const Center(
                    child: Text(
                      "Camera permission required",
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                  ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: scannedData == null
                  ? Text(
                      errorMessage ?? "Scan a QR code",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      onPressed: () {
                        try {
                          List<Map<String, dynamic>> parsed =
                              List<Map<String, dynamic>>.from(jsonDecode(scannedData!));
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => ItemChecklistPage(data: parsed),
                            ),
                          );
                        } catch (e) {
                          setState(() {
                            errorMessage = "Invalid QR data structure.";
                            scannedData = null;
                          });
                          controller.start(); // restart scanning
                        }
                      },
                      child: const Text("Proceed"),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
