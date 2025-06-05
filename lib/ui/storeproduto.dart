import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:nitroscanmobile/ui/class/scannerpage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nitroscanmobile/ui/class/usuario.dart';

class StoreProduto extends StatefulWidget {
  final String baseUrl;

  const StoreProduto({super.key, required this.baseUrl});

  @override
  State<StoreProduto> createState() => _StoreProdutoState();
}

class _StoreProdutoState extends State<StoreProduto> {
  final _formKey = GlobalKey<FormState>();
  late AuthService authService;
  String? nomeUsuario;

  final TextEditingController eanController = TextEditingController();
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController fabricanteController = TextEditingController();
  final TextEditingController anoFabricacaoController = TextEditingController();
  final TextEditingController vencimentoController = TextEditingController();
  final TextEditingController valorController = TextEditingController();

  File? _imagemSelecionada;
  bool _isLoading = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    authService = AuthService(baseUrl: widget.baseUrl);
    buscarUsuario();
  }

  @override
  void dispose() {
    eanController.dispose();
    nomeController.dispose();
    descricaoController.dispose();
    fabricanteController.dispose();
    anoFabricacaoController.dispose();
    vencimentoController.dispose();
    valorController.dispose();
    super.dispose();
  }

  Future<void> _selecionarImagem() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Tirar foto'),
                onTap: () async {
                  final XFile? foto = await picker.pickImage(source: ImageSource.camera);
                  if (foto != null) {
                    setState(() => _imagemSelecionada = File(foto.path));
                  }
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.image),
                title: Text('Escolher da galeria'),
                onTap: () async {
                  final XFile? imagem = await picker.pickImage(source: ImageSource.gallery);

                  if (imagem != null) {
                    final file = File(imagem.path);
                    final int fileSize = await file.length();

                    if (fileSize > 10 * 1024 * 1024) { // 10MB
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Imagem muito grande. Tamanho máximo permitido: 10MB.')),
                      );
                      return;
                    }

                    setState(() => _imagemSelecionada = file);
                  }
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
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

  Future<void> _cadastrarProduto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token não encontrado. Faça login novamente.')),
      );
      setState(() => _isLoading = false);
      return;
    }

    final uri = Uri.parse('${widget.baseUrl}api/produtos');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['codigo_ean'] = eanController.text.trim()
      ..fields['nome'] = nomeController.text.trim()
      ..fields['descricao'] = descricaoController.text.trim()
      ..fields['fabricante'] = fabricanteController.text.trim()
      ..fields['ano_fabricacao'] = anoFabricacaoController.text.trim()
      ..fields['data_vencimento'] = vencimentoController.text.trim()
      ..fields['valor'] = valorController.text.trim();

    if (_imagemSelecionada != null) {
      request.files.add(await http.MultipartFile.fromPath('imagem', _imagemSelecionada!.path));
    }

    try {
      final response = await request.send();

      if (response.statusCode == 201) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto cadastrado com sucesso!')),
        );
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
      } else {
        final respStr = await response.stream.bytesToString();
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $respStr')),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _abrirScanner() async {
    final codigo = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerSimplesPage()),
    );

    if (codigo != null && mounted) {
      setState(() {
        eanController.text = codigo;
      });
    }
  }

  String? eanValidator(String? value) {
    if (value == null || value.isEmpty) return 'Preencha Código EAN';
    final regex = RegExp(r'^[0-9]+$');
    if (!regex.hasMatch(value)) return 'Código EAN deve conter apenas números';
    return null;
  }

  String? anoValidator(String? value) {
    if (value == null || value.isEmpty) return 'Preencha Ano de Fabricação';
    final year = int.tryParse(value);
    if (year == null) return 'Ano inválido';
    if (year < 1901 || year > DateTime.now().year) return 'Ano fora do intervalo permitido';
    return null;
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Image.asset('assets/image/ondaDeBaixo.png', fit: BoxFit.cover),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Image.asset('assets/image/ondaDeCima.png', fit: BoxFit.cover),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text('Cadastro de Produto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _campoTexto(
                            controller: eanController,
                            label: 'Código EAN',
                            keyboardType: TextInputType.number,
                            validator: eanValidator,
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

                    _campoTexto(controller: nomeController, label: 'Nome'),
                    _campoTexto(controller: descricaoController, label: 'Descrição'),
                    _campoTexto(controller: fabricanteController, label: 'Fabricante'),

                    Row(
                      children: [
                        Expanded(
                          child: _campoTexto(
                            controller: anoFabricacaoController,
                            label: 'Ano de Fabricação',
                            keyboardType: TextInputType.number,
                            validator: anoValidator,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _campoTexto(
                            controller: valorController,
                            label: 'Valor',
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Preencha Valor';
                              if (double.tryParse(value) == null) return 'Valor inválido';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: vencimentoController,
                      readOnly: true,
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          vencimentoController.text = picked.toIso8601String().split('T').first;
                        }
                      },
                      validator: (value) => value == null || value.isEmpty ? 'Selecione a data de vencimento' : null,
                      decoration: InputDecoration(
                        labelText: 'Data de Vencimento',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selecionarImagem,
                            label: Text(_imagemSelecionada == null ? 'Selecionar Imagem' : 'Trocar Imagem'),
                            icon: Icon(Icons.image),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.teal,
                              minimumSize: Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _cadastrarProduto,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 20, 121, 189),
                              minimumSize: Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : const Text('Cadastrar', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _campoTexto({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator ??
            (value) {
              if (value == null || value.isEmpty) return 'Preencha $label';
              return null;
            },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }
}
