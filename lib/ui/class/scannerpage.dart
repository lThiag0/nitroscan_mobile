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

  bool validarEAN(String codigo) {
    if (codigo.length != 13 && codigo.length != 8) return false;

    final digits = codigo.split('').map(int.tryParse).toList();
    if (digits.contains(null)) return false;

    final int length = codigo.length;
    final int checkDigit = digits.removeLast()!;

    int sum = 0;
    for (int i = 0; i < digits.length; i++) {
      int weight = (length == 13)
          ? (i % 2 == 0 ? 1 : 3)
          : (i % 2 == 0 ? 3 : 1); // EAN-13 / EAN-8 diferente
      sum += digits[i]! * weight;
    }

    int calculatedDigit = (10 - (sum % 10)) % 10;
    return checkDigit == calculatedDigit;
  }

  void _processarCodigo(String codigo) {
    if (validarEAN(codigo)) {
      Navigator.pop(context, codigo);
    } else {
      setState(() => _codigoLido = false);
    }
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
              _processarCodigo(codigo);
            });
          }
        },
      ),
    );
  }
}
