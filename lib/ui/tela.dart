import 'package:flutter/material.dart';
import 'package:nitroscanmobile/ui/class/users.dart';
import 'package:nitroscanmobile/ui/class/usuario.dart';
import 'package:package_info_plus/package_info_plus.dart';

class TelaPage extends StatefulWidget {
  final String baseUrl;

  const TelaPage({super.key, required this.baseUrl});

  @override
  State<TelaPage> createState() => _TelaPageState();
}

class _TelaPageState extends State<TelaPage> {
  AuthService? authService;
  Usuario? usuario;
  String appVersion = '';
  String apiVersion = 'v1.0';
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    authService = AuthService(baseUrl: widget.baseUrl);
    carregarDados();
  }

  Future<void> carregarDados() async {
    final user = await authService?.buscarUsuarioCompleto(context);
    final info = await PackageInfo.fromPlatform();

    setState(() {
      usuario = user;
      appVersion = "${info.version} (${info.buildNumber})";
    });
  }

  void logout() async {
    setState(() => _isLoggingOut = true);

    await authService?.logout(context);

    setState(() => _isLoggingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(usuario?.nome ?? 'Carregando...', style: TextStyle(color: Colors.white)),
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

          // Conteúdo
          Center(
            child: 
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: usuario == null
                  ? CircularProgressIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset('assets/image/Nitro.png', height: 120),
                        SizedBox(height: 60),
                        // Foto circular
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage('assets/image/semavatar.png'),
                        ),
                        const SizedBox(height: 20),

                        // Nome
                        Text(
                          usuario!.nome,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),

                        // Código (ID)
                        Text("Código Interno: ${usuario!.id}", style: TextStyle(fontSize: 16)),

                        // Email
                        Text("Email: ${usuario!.email}", style: TextStyle(fontSize: 16)),

                        const SizedBox(height: 40),
                        Divider(),

                        // Versões
                        Text("Versão do app: $appVersion", style: TextStyle(color: Colors.grey[700])),
                        Text("Versão da API: $apiVersion", style: TextStyle(color: Colors.grey[700])),
                        SizedBox(height: 100),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
