import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:iiitnr/labchecklist.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class LabInchargeScannerPage extends StatefulWidget {
  final String scannerPermission; // e.g., 'LabA', 'Sports', 'LabB'

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
          scannedData = null;
          try {
            final decoded = jsonDecode(code);
            if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
              final Map<String, dynamic> firstItem = decoded.first;
              final String qrPermission = firstItem['permission'] ?? '';
              if (qrPermission != widget.scannerPermission) {
                errorMessage = "Scan rejected: permission mismatch.";
                scannedData = null;
                return;
              }
              scannedData = code;
              errorMessage = null;
            } else {
              errorMessage = "Invalid QR structure.";
            }
          } catch (e) {
            errorMessage = "Invalid QR code format.";
          }
        });
        controller.stop();
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
      appBar: AppBar(title: Text("${widget.scannerPermission} Incharge Scanner")),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: hasPermission
                ? MobileScanner(
                    controller: controller,
                    onDetect: handleDetection,
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
                    ? Text(errorMessage ?? "Scan a QR code",
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center)
                    : ElevatedButton(
                        onPressed: () {
                          try {
                            final List<Map<String, dynamic>> parsed = List<Map<String, dynamic>>.from(
                                jsonDecode(scannedData!));
                            Navigator.of(context).pushReplacement(MaterialPageRoute(
                                builder: (context) => LabChecklistPage(
                                      data: parsed,
                                      labCollectionName: widget.scannerPermission.toLowerCase() + "equipment",
                                    )
                                  )
                                );
                          } catch (e) {
                            setState(() {
                              errorMessage = "Invalid QR data structure.";
                              scannedData = null;
                            });
                            controller.start();
                          }
                        },
                        child: const Text("Proceed"),
                      ),
              ))
        ],
      ),
    );
  }
}
