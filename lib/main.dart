import 'package:flutter/material.dart';
import 'package:nitroscanmobile/ui/buscarproduto.dart';
import 'package:nitroscanmobile/ui/loginpage.dart';
import 'package:nitroscanmobile/ui/home.dart';
import 'package:nitroscanmobile/ui/produtos.dart';
import 'package:nitroscanmobile/ui/storeproduto.dart';
import 'package:nitroscanmobile/ui/tela.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final String baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:8000/';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NitroScan',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/': (context) => HomePage(baseUrl: baseUrl),
        '/login': (context) => LoginPage(baseUrl: baseUrl),
        '/produtos': (context) => ProdutosPage(baseUrl: baseUrl),
        '/storeprodutos': (context) => StoreProduto(baseUrl: baseUrl),
        '/buscarprodutos': (context) => BuscarProdutoPage(baseUrl: baseUrl),
        '/tela': (context) => TelaPage(baseUrl: baseUrl),
      },
    );
  }
}
