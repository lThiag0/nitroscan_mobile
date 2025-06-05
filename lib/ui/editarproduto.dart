import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nitroscanmobile/ui/class/usuario.dart';

class EditProduto extends StatefulWidget {
  final String baseUrl;
  final Map<String, dynamic> produto;

  const EditProduto({super.key, required this.baseUrl, required this.produto});

  @override
  State<EditProduto> createState() => _EditProdutoState();
}

class _EditProdutoState extends State<EditProduto> {
  final _formKey = GlobalKey<FormState>();
  late final authService = AuthService(baseUrl: widget.baseUrl);
  String? nomeUsuario;

  late TextEditingController eanController;
  late TextEditingController nomeController;
  late TextEditingController descricaoController;
  late TextEditingController fabricanteController;
  late TextEditingController anoFabricacaoController;
  late TextEditingController vencimentoController;
  late TextEditingController valorController;

  File? _imagemSelecionada;
  bool _isLoading = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    buscarUsuario();

    eanController = TextEditingController(text: widget.produto['codigo_ean']);
    nomeController = TextEditingController(text: widget.produto['nome']);
    descricaoController = TextEditingController(text: widget.produto['descricao']);
    fabricanteController = TextEditingController(text: widget.produto['fabricante']);
    anoFabricacaoController = TextEditingController(text: widget.produto['ano_fabricacao'].toString());
    vencimentoController = TextEditingController(text: widget.produto['data_vencimento']);
    valorController = TextEditingController(text: widget.produto['valor'].toString());
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

  Future<void> _selecionarImagem() async {
    final picker = ImagePicker();
    final XFile? imagem = await picker.pickImage(source: ImageSource.gallery);
    if (imagem != null) setState(() => _imagemSelecionada = File(imagem.path));
  }

  void _mostrarImagem() {
    Widget? imagemWidget;

    if (_imagemSelecionada != null) {
      imagemWidget = Image.file(_imagemSelecionada!, width: 300, height: 300);
    } else if (widget.produto['imagem_url'] != null && widget.produto['imagem_url'].toString().isNotEmpty) {
      imagemWidget = Image.network(
        widget.produto['imagem_url'],
        width: 300,
        height: 300,
        errorBuilder: (context, error, stackTrace) {
          return const Text('Erro ao carregar imagem');
        },
      );
    } else {
      imagemWidget = const Text('Nenhuma imagem disponível');
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(content: imagemWidget),
    );
  }

  Future<void> _atualizarProduto() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Token não encontrado.')));
      return;
    }

    final uri = Uri.parse('${widget.baseUrl}api/produtos/${widget.produto['codigo_ean']}');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['_method'] = 'PUT'
      ..fields['codigo_ean'] = eanController.text
      ..fields['nome'] = nomeController.text
      ..fields['descricao'] = descricaoController.text
      ..fields['fabricante'] = fabricanteController.text
      ..fields['ano_fabricacao'] = anoFabricacaoController.text
      ..fields['data_vencimento'] = vencimentoController.text
      ..fields['valor'] = valorController.text;

    if (_imagemSelecionada != null) {
      request.files.add(await http.MultipartFile.fromPath('imagem', _imagemSelecionada!.path));
    }

    try {
      final response = await request.send();
      final body = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Produto atualizado com sucesso!')));
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $body')));
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro de conexão: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _excluirProduto() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir Produto'),
        content: Text('Tem certeza que deseja excluir este produto?'),
        actions: [
          TextButton(
            child: Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 236, 186, 182)),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Token não encontrado.')));
      return;
    }

    final url = Uri.parse('${widget.baseUrl}api/produtos/${widget.produto['codigo_ean']}');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produto excluído com sucesso.')),
        );
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir: ${response.body}')),
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

  Widget _campoTexto({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator ?? (v) => v == null || v.isEmpty ? 'Preencha $label' : null,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          filled: true,
          fillColor: readOnly ? Colors.grey[200] : Colors.grey[100], // cor diferenciada
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(nomeUsuario ?? 'Carregando...', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 20, 121, 189),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.white),
            onPressed: _isLoading ? null : _excluirProduto,
          ),
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
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned(top: 0, left: 0, right: 0, height: 100, child: Image.asset('assets/image/ondaDeBaixo.png', fit: BoxFit.cover)),
          Positioned(bottom: 0, left: 0, right: 0, height: 100, child: Image.asset('assets/image/ondaDeCima.png', fit: BoxFit.cover)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Text('Editar Produto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    SizedBox(height: 20),
                    _campoTexto(controller: eanController, label: 'Código EAN', keyboardType: TextInputType.number, readOnly: true, validator: null,),
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
                            validator: (v) => v == null || v.isEmpty || int.tryParse(v) == null ? 'Ano inválido' : null,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _campoTexto(
                            controller: valorController,
                            label: 'Valor',
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            validator: (v) => v == null || v.isEmpty || double.tryParse(v) == null ? 'Valor inválido' : null,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: vencimentoController,
                      readOnly: true,
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.tryParse(vencimentoController.text) ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          vencimentoController.text = picked.toIso8601String().split('T').first;
                        }
                      },
                      validator: (v) => v == null || v.isEmpty ? 'Selecione a data de vencimento' : null,
                      decoration: InputDecoration(
                        labelText: 'Data de Vencimento',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    SizedBox(height: 16),
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
                        SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.visibility, color: Colors.white),
                            onPressed: _mostrarImagem,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _atualizarProduto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 20, 121, 189),
                        minimumSize: Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('Salvar', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
