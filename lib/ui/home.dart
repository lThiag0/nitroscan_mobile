import 'package:flutter/material.dart';
import 'package:nitroscanmobile/ui/class/usuario.dart';

class HomePage extends StatefulWidget {
  final String baseUrl;
  const HomePage({super.key, required this.baseUrl});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late AuthService authService;
  String? nomeUsuario;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    authService = AuthService(baseUrl: widget.baseUrl);
    buscarUsuario();
  }

  // Buscar usuário
  Future<void> buscarUsuario() async {
    final nome = await authService.buscarUsuario(context);
    setState(() {
      nomeUsuario = nome ?? 'Usuário';
    });
  }

  // Logout
  void logout() async {
    setState(() => _isLoggingOut = true);

    await authService.logout(context);

    setState(() => _isLoggingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          nomeUsuario ?? 'Carregando...',
          style: TextStyle(color: Colors.white),
        ),
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
            height: screenHeight * 0.15,
            child: Image.asset(
              'assets/image/ondaDeBaixo.png',
              fit: BoxFit.cover,
            ),
          ),

          // Conteúdo principal
          Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/image/Nitro.png', height: 120),
                        SizedBox(height: 50),

                        // Botão 1
                        SizedBox(
                          width: 300,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/produtos');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 20, 121, 189),
                              minimumSize: Size(double.infinity, 50),
                            ),
                            child: Text('Escanear produto', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Botão 2
                        SizedBox(
                          width: 300,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/storeprodutos');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 20, 121, 189),
                              minimumSize: Size(double.infinity, 50),
                            ),
                            child: Text('Cadastrar Produto', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Botão 3
                        SizedBox(
                          width: 300,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/buscarprodutos');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 20, 121, 189),
                              minimumSize: Size(double.infinity, 50),
                            ),
                            child: Text('Editar produto', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                        SizedBox(height: 20),

                        // Botão 4
                        SizedBox(
                          width: 300,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/tela');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 20, 121, 189),
                              minimumSize: Size(double.infinity, 50),
                            ),
                            child: Text('Informações', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: EdgeInsets.only(bottom: screenHeight * 0.2),
                child: Text(
                  'Criado por Thiago Araujo e Gabriel Lopes',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
            ],
          ),

          // Onda inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.15,
            child: Image.asset(
              'assets/image/ondaDeCima.png',
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
