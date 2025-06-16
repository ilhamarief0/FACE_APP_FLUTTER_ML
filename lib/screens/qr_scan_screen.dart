import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:io';

class QrScanScreen extends StatefulWidget {
  final Function(String qrData) onQrScanned;

  const QrScanScreen({Key? key, required this.onQrScanned}) : super(key: key);

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessingScan = false;
  String _lastScannedData = "Belum ada QR Code terdeteksi.";

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pindai QR Code Kelas', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.blue,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: MediaQuery.of(context).size.width * 0.8,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.black87,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Arahkan kamera ke QR Code kelas',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _lastScannedData,
                    style: const TextStyle(color: Colors.yellow, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    print('QRViewController berhasil dibuat dan stream dimulai.');

    controller.scannedDataStream.listen((scanData) {
      if (_isProcessingScan) return; // Mencegah pemrosesan ganda

      if (scanData.code != null && scanData.code!.isNotEmpty) {
        _isProcessingScan = true; // Set flag
        controller.pauseCamera(); // Hentikan kamera

        print('QR Scan Data diterima: ${scanData.code}'); // Log data yang dipindai
        setState(() {
          _lastScannedData = "Terdeteksi: ${scanData.code}"; // Update UI dengan data terdeteksi
        });

        // Panggil callback dan pop screen dengan data
        // Ini akan mengembalikan data ke _startQrScan di HomePage
        widget.onQrScanned(scanData.code!);
        Navigator.pop(context, scanData.code!); // Pastikan data dikembalikan di sini
      } else {
        print('Data QR Code kosong atau tidak valid.');
        setState(() {
          _lastScannedData = "Terdeteksi (kosong atau tidak valid).";
        });
        // Jika tidak ada data valid, jangan set _isProcessingScan = true
        // Biarkan scanner terus memindai
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
