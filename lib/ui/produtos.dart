import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:nitroscanmobile/ui/class/scancamera.dart';
import 'package:nitroscanmobile/ui/class/usuario.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProdutosPage extends StatefulWidget {
  final String baseUrl;

  const ProdutosPage({super.key, required this.baseUrl});

  @override
  // ignore: library_private_types_in_public_api
  _ProdutosPageState createState() => _ProdutosPageState();
}

class _ProdutosPageState extends State<ProdutosPage> {
  late AuthService authService;
  final TextEditingController codigoController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  bool _isLoading = false;
  String? nomeUsuario;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    focusNode.addListener(() {
      if (focusNode.hasFocus) {
        _moverCursorParaUltimaLinha();
      }
    });
    authService = AuthService(baseUrl: widget.baseUrl);
    buscarUsuario();
    buscarCodigos();
  }

  void _moverCursorParaUltimaLinha() {
    final textoAtual = codigoController.text;
    if (textoAtual.isNotEmpty && !textoAtual.endsWith('\n')) {
      codigoController.text = '$textoAtual\n';
    }
    codigoController.selection = TextSelection.fromPosition(
      TextPosition(offset: codigoController.text.length),
    );
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

  Future<void> buscarCodigos() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('${widget.baseUrl}api/eans');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> codigos = jsonDecode(response.body);
        final texto = codigos.join('\n');

        setState(() {
          codigoController.text = texto;
        });
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar códigos: ${response.statusCode}!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro na conexão: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void salvarCodigo() async {
    if (codigoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi encontrado nenhum código escaneado!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final novosCodigos = {
      ...codigoController.text
          .split('\n')
          .map((e) => e.trim().replaceAll(',', ''))
          .where((e) => e.isNotEmpty)
    }.toList();

    if (novosCodigos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nenhum código válido foi encontrado.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final codigosInvalidos = novosCodigos
        .where((codigo) => !RegExp(r'^\d+$').hasMatch(codigo))
        .toList();

    if (codigosInvalidos.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Há códigos inválidos (com letras ou símbolos): ${codigosInvalidos.join(', ')}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final codigosString = novosCodigos.join(',');

    try {
      final url = Uri.parse('${widget.baseUrl}api/registrar-eans');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'codigos_ean': codigosString}),
      );

      if (response.statusCode == 200) {
        codigoController.clear();

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Códigos enviados com sucesso!')),
        );

        // ignore: use_build_context_synchronously
        Navigator.pop(context);
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar: ${response.statusCode}')),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }

    setState(() {});
  }

  Future<void> limparCodigosApi() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar limpeza'),
        content: const Text('Tem certeza que deseja apagar todos os códigos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    final url = Uri.parse('${widget.baseUrl}api/limpar-eans');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          codigoController.clear();
        });

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Códigos removidos com sucesso!')),
        );
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao remover códigos: ${response.statusCode}')),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro na conexão: $e')),
      );
    }
  }

  @override
  void dispose() {
    codigoController.dispose();
    super.dispose();
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
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
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Escaneie ou digite o código de barras:',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: 350,
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final codigosEscaneados = await Navigator.push<List<String>>(
                                      context,
                                      MaterialPageRoute(builder: (context) => ScannerPage()),
                                    );

                                    if (codigosEscaneados != null && codigosEscaneados.isNotEmpty) {
                                      setState(() {
                                        for (var codigo in codigosEscaneados) {
                                          final textoAtual = codigoController.text.trimRight();
                                          final novoTexto = textoAtual.isEmpty
                                              ? '$codigo,\n'
                                              : '$textoAtual\n$codigo,\n';
                                          codigoController.text = novoTexto;
                                          codigoController.selection = TextSelection.fromPosition(
                                            TextPosition(offset: codigoController.text.length),
                                          );
                                        }
                                      });
                                    }
                                  },
                                  icon: Icon(Icons.qr_code_scanner, color: Colors.white),
                                  label: Text('Scan Câmera', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 20, 121, 189),
                                    minimumSize: Size(double.infinity, 50),
                                  ),
                                ),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: buscarCodigos,
                                  icon: Icon(Icons.refresh_outlined, color: Colors.white),
                                  label: Text('Recarregar', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 20, 121, 189),
                                    minimumSize: Size(double.infinity, 50),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 15),
                        SizedBox(
                          width: 350,
                          child: TextField(
                            controller: codigoController,
                            focusNode: focusNode,
                            maxLines: 10,
                            decoration: InputDecoration(
                              hintText: 'Código de barras...',
                              border: OutlineInputBorder(),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        SizedBox(
                          width: 350,
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: limparCodigosApi,
                                  icon: Icon(Icons.clear, color: Colors.white),
                                  label: Text('Limpar', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color.fromARGB(255, 247, 65, 65),
                                    minimumSize: Size(double.infinity, 50),
                                  ),
                                ),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: salvarCodigo,
                                  icon: Icon(Icons.save, color: Colors.white),
                                  label: Text('Salvar', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(255, 20, 121, 189),
                                    minimumSize: Size(double.infinity, 50),
                                  ),
                                ),
                              ),
                            ],
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
