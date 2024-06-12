import 'package:flutter/material.dart';
import 'package:realtime_supabase/configuracoes.dart';
import 'package:realtime_supabase/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//flutter run -d chrome --web-renderer html
//Erro de cors ao tentar carregar a imagem

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: '',
    anonKey: '',
  );
  runApp(const RealtimeSupabase());
}

class RealtimeSupabase extends StatelessWidget {
  const RealtimeSupabase({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Realtime Supabase',
      theme: appTheme,
      home: const LoginPage(),
      routes: {
        "/login_page": (context) => const LoginPage(),
      },
    );
  }
}
