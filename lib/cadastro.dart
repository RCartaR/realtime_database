import 'package:flutter/material.dart';
import 'package:realtime_supabase/chat.dart';
import 'package:realtime_supabase/login.dart';
import 'package:realtime_supabase/configuracoes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key, required this.isRegistering}) : super(key: key);

  static Route<void> route({bool isRegistering = false}) {
    return MaterialPageRoute(
      builder: (context) => RegisterPage(isRegistering: isRegistering),
    );
  }

  final bool isRegistering;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _avatarController = TextEditingController();

  Future<void> _signUp() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }
    final email = _emailController.text;
    final password = _passwordController.text;
    final username = _usernameController.text;
    final avatar = _avatarController.text;
    try {
      await supabase.auth.signUp(
          email: email,
          password: password,
          data: {'username': username, 'avatar': avatar});
      Navigator.of(context)
          .pushAndRemoveUntil(ChatPage.route(), (route) => false);
    } on AuthException catch (error) {
      context.showErrorSnackBar(message: error.message);
    } catch (error) {
      context.showErrorSnackBar(message: unexpectedErrorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: formPadding,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                label: Text('Email'),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Required';
                }
                return null;
              },
              keyboardType: TextInputType.emailAddress,
            ),
            formSpacer,
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                label: Text('Senha'),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Required';
                }
                if (val.length < 6) {
                  return 'mínimo de 6 caracteres';
                }
                return null;
              },
            ),
            formSpacer,
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                label: Text('Nome de usuário'),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Required';
                }
                final isValid = RegExp(r'^[A-Za-z0-9_]{3,24}$').hasMatch(val);
                if (!isValid) {
                  return '3 a 24 caracteres alfanuméricos';
                }
                return null;
              },
            ),
            formSpacer,
            TextFormField(
              controller: _avatarController,
              decoration: const InputDecoration(
                label: Text('URL do avatar'),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
            formSpacer,
            Center(
              child: SizedBox(
                width: buttonWidth,
                child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    child: const Text('Cadastrar')),
              ),
            ),
            formSpacer,
            Center(
              child: SizedBox(
                width: buttonWidth,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(LoginPage.route());
                  },
                  child: const Text('Já possuo uma conta'),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
