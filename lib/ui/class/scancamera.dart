import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ScannerPageState createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final MobileScannerController cameraController = MobileScannerController(
    formats: [BarcodeFormat.ean13, BarcodeFormat.ean8],
  );

  final Set<String> codigosLidos = {};
  late final AudioPlayer _player;
  bool isTorchOn = false;
  bool isScanning = false;
  late final GlobalKey<AnimatedListState> _listKey;
  bool _dialogAberto = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _listKey = GlobalKey<AnimatedListState>();
  }

  @override
  void dispose() {
    _player.dispose();
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _playBeep() async {
    try {
      await _player.play(AssetSource('sound/beepscan.mp3'));
    } catch (e) {
      debugPrint('Erro ao tocar o beep: ${e.toString()}');
    }
  }

  void _toggleTorch() {
    setState(() {
      isTorchOn = !isTorchOn;
    });
    cameraController.toggleTorch();
  }

  void _removerCodigo(String codigo) {
    final index = codigosLidos.toList().indexOf(codigo);
    if (index >= 0) {
      setState(() {
        codigosLidos.remove(codigo);
      });
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => SizeTransition(
          sizeFactor: animation,
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: Colors.red[100],
            child: ListTile(
              title: Text(
                codigo,
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          ),
        ),
        duration: Duration(milliseconds: 400),
      );
    }
  }

  void _finalizar() {
    if (codigosLidos.isEmpty) {
      Navigator.pop(context);
    } else {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text('Finalizar escaneamento?'),
              content: Text(
                'Você leu ${codigosLidos.length} código(s). Deseja confirmar?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, codigosLidos.toList());
                  },
                  child: Text('Confirmar'),
                ),
              ],
            ),
      );
    }
  }

  Future<void> _mostrarAlertaCodigoRepetido(String codigo) async {
    if (_dialogAberto) return;
    _dialogAberto = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text('Código já escaneado'),
            content: Text('O código $codigo já foi lido.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _dialogAberto = false;
                },
                child: Text('Continuar'),
              ),
            ],
          ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture barcodeCapture) async {
    if (isScanning) return;

    setState(() {
      isScanning = true;
    });

    String? novoCodigo;

    for (final barcode in barcodeCapture.barcodes) {
      final code = barcode.rawValue;

      if (code != null && code.isNotEmpty) {
        if (!validarEAN(code)) {
          setState(() {
            isScanning = false;
          });
          break;
        }

        if (!codigosLidos.contains(code)) {
          novoCodigo = code;
          break;
        } else {
          HapticFeedback.heavyImpact();
          await _mostrarAlertaCodigoRepetido(code);
          break;
        }
      }
    }

    if (novoCodigo != null) {
      setState(() {
        codigosLidos.add(novoCodigo!);
        _listKey.currentState?.insertItem(codigosLidos.length - 1);
      });

      await _playBeep();
      HapticFeedback.mediumImpact();
    }

    await Future.delayed(Duration(milliseconds: 1500));

    setState(() {
      isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Escaneando Vários Códigos',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 20, 121, 189),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
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
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),
            tooltip: 'Finalizar escaneamento',
            onPressed: _finalizar,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: cameraController,
                  onDetect: _onBarcodeDetected,
                ),
                if (isScanning)
                  Container(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Escaneando...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (codigosLidos.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total de códigos lidos: ${codigosLidos.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueGrey,
                    ),
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: AnimatedList(
                      key: _listKey,
                      initialItemCount: codigosLidos.length,
                      itemBuilder: (context, index, animation) {
                        final codigo = codigosLidos.elementAt(index);
                        return SizeTransition(
                          sizeFactor: animation,
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(1.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 16.0),
                                    child: Text(
                                      codigo,
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      _removerCodigo(codigo);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Função para validar EAN-13 e EAN-8 com base no dígito verificador
bool validarEAN(String codigo) {
  if (!RegExp(r'^\d+$').hasMatch(codigo)) return false;
  if (codigo.length != 8 && codigo.length != 13) return false;

  final digits = codigo.split('').map(int.parse).toList();
  final checkDigit = digits.removeLast();

  int sum = 0;
  for (int i = 0; i < digits.length; i++) {
    int weight;
    if (codigo.length == 13) {
      weight = (i % 2 == 0) ? 1 : 3;
    } else {
      weight = (i % 2 == 0) ? 3 : 1;
    }
    sum += digits[i] * weight;
  }

  int expectedCheckDigit = (10 - (sum % 10)) % 10;
  return checkDigit == expectedCheckDigit;
}