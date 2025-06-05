import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nitroscanmobile/ui/class/scannerpage.dart';
import 'dart:convert';
import 'package:nitroscanmobile/ui/editarproduto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nitroscanmobile/ui/class/usuario.dart';

class BuscarProdutoPage extends StatefulWidget {
  final String baseUrl;

  const BuscarProdutoPage({super.key, required this.baseUrl});

  @override
  State<BuscarProdutoPage> createState() => _BuscarProdutoPageState();
}

class _BuscarProdutoPageState extends State<BuscarProdutoPage> {
  final TextEditingController _eanController = TextEditingController();
  bool _isLoading = false;
  bool _isLoggingOut = false;
  String? nomeUsuario;
  late AuthService authService;

  @override
  void initState() {
    super.initState();
    authService = AuthService(baseUrl: widget.baseUrl);
    buscarUsuario();
  }

  Future<void> buscarUsuario() async {
    final nome = await authService.buscarUsuario(context);
    setState(() {
      nomeUsuario = nome ?? 'Usuário';
    });
  }

  void logout() async {
    setState(() => _isLoggingOut = true);

    await authService.logout(context);

    setState(() => _isLoggingOut = false);
  }

  Future<void> _abrirScanner() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScannerSimplesPage(),
      ),
    );

    if (resultado != null && resultado is String) {
      setState(() {
        _eanController.text = resultado;
      });
      // Agora o usuário pode editar antes de buscar
    }
  }

  Future<void> _buscarProduto() async {
    final ean = _eanController.text.trim();
    if (ean.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        _mostrarErro('Token não encontrado. Faça login novamente.');
        return;
      }

      final url = Uri.parse('${widget.baseUrl}api/produtos/ean/$ean');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true && data['data'] != null) {
        final produto = data['data'];
        Navigator.push(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) => EditProduto(
              baseUrl: widget.baseUrl,
              produto: produto,
            ),
          ),
        );
      } else {
        _mostrarErro(data['message'] ?? 'Produto não encontrado.');
      }

    } catch (e) {
      _mostrarErro('Erro de conexão: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(nomeUsuario ?? 'Carregando...', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isLoggingOut
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            )
          : IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: logout,
            ),
        ],
        backgroundColor: const Color.fromARGB(255, 20, 121, 189),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Onda superior
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Image.asset(
              'assets/image/ondaDeBaixo.png',
              fit: BoxFit.cover,
            ),
          ),

          // Onda inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Image.asset(
              'assets/image/ondaDeCima.png',
              fit: BoxFit.cover,
            ),
          ),

          // Conteúdo central
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Buscar Produto por EAN',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _eanController,
                          decoration: const InputDecoration(
                            labelText: 'Código EAN',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.numberWithOptions(
                            signed: false,
                            decimal: false,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 20, 121, 189),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                          tooltip: 'Escanear Código',
                          onPressed: _abrirScanner,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _buscarProduto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 20, 121, 189),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Buscar',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
