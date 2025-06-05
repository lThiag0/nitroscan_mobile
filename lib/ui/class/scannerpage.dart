import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerSimplesPage extends StatefulWidget {
  const ScannerSimplesPage({super.key});

  @override
  State<ScannerSimplesPage> createState() => _ScannerSimplesPageState();
}

class _ScannerSimplesPageState extends State<ScannerSimplesPage> {
  final MobileScannerController cameraController = MobileScannerController(
    formats: [BarcodeFormat.ean13, BarcodeFormat.ean8],
  );

  bool _codigoLido = false;
  bool isTorchOn = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _toggleTorch() {
    setState(() {
      isTorchOn = !isTorchOn;
    });
    cameraController.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Escanear Código EAN',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 20, 121, 189),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _toggleTorch,
            icon: Icon(
              isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: isTorchOn ? Colors.yellow : Colors.white,
            ),
          ),
        ],
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          if (_codigoLido) return;

          final List<Barcode> barcodes = capture.barcodes;
          final String? codigo = barcodes.first.rawValue;

          if (codigo != null) {
            setState(() => _codigoLido = true);

            Future.delayed(const Duration(milliseconds: 200), () {
              // ignore: use_build_context_synchronously
              Navigator.pop(context, codigo);
            });
          }
        },
      ),
    );
  }
}
