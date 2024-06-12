import 'dart:async';
import 'package:flutter/material.dart';
import 'package:realtime_supabase/mensagem.dart';
import 'package:realtime_supabase/perfil.dart';
import 'package:realtime_supabase/configuracoes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  static Route<void> route() {
    return MaterialPageRoute(
      builder: (context) => const ChatPage(),
    );
  }

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final Stream<List<Message>> _messagesStream;
  final Map<String, Profile> _profileCache = {};

  @override
  void initState() {
    final myUserId = supabase.auth.currentUser!.id;
    _messagesStream = supabase
        .from('messages')
        /* é uma query que mantém a conexão aberta procurando atualizações, 
        caso contrário usaria um select que atualizaria, e fecharia a operação*/
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((maps) => maps
            .map((map) => Message.fromMap(map: map, myUserId: myUserId))
            .toList());
    super.initState();
  }

  Future<void> _loadProfileCache(String profileId) async {
    if (_profileCache[profileId] != null) {
      return;
    }
    final data =
        await supabase.from('profiles').select().eq('id', profileId).single();
    final profile = Profile.fromMap(data);
    setState(() {
      _profileCache[profileId] = profile;
    });
  }

  void _logout(BuildContext context) async {
    await supabase.auth.signOut();
    Navigator.pushReplacementNamed(context, '/login_page');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            tooltip: 'Sair',
            icon: Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: StreamBuilder<List<Message>>(
        stream: _messagesStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final messages = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? const Center(
                          child: Text('Comece a sua conversa!'),
                        )
                      : ListView.builder(
                          reverse: true,
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final message = messages[index];

                            _loadProfileCache(message.profileId);

                            return _ChatBubble(
                              message: message,
                              profile: _profileCache[message.profileId],
                            );
                          },
                        ),
                ),
                const _MessageBar(),
              ],
            );
          } else {
            return preloader;
          }
        },
      ),
    );
  }
}

// Campo de texto e botão para poder mandar a mensagem
class _MessageBar extends StatefulWidget {
  const _MessageBar({
    Key? key,
  }) : super(key: key);

  @override
  State<_MessageBar> createState() => _MessageBarState();
}

class _MessageBarState extends State<_MessageBar> {
  late final TextEditingController _textController;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  keyboardType: TextInputType.text,
                  maxLines: null,
                  autofocus: true,
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Escreva uma mensagem',
                    border: OutlineInputBorder(),
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.all(8),
                  ),
                  onFieldSubmitted: (value) {
                    _submitMessage();
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                tooltip: 'Enviar',
                onPressed: () => _submitMessage(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    _textController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  //Função assíncrona que manda a mensagem para o banco apenas quando chamada
  void _submitMessage() async {
    final text = _textController
        .text; //Armazena o conteúdo do controlador _textController
    final myUserId = supabase.auth.currentUser!.id; //Armazena o Id do usuário
    if (text.isEmpty) {
      return;
    }
    _textController.clear(); //Limpa a caixa de mensagem após o envio do texto
    //Insere os dados de Id do usuário e a mensagem na tabela messages do banco
    try {
      await supabase.from('messages').insert({
        'profile_id': myUserId,
        'content': text,
      });
      //Mensagens de erro
    } on PostgrestException catch (error) {
      context.showErrorSnackBar(message: error.message);
    } catch (_) {
      context.showErrorSnackBar(message: unexpectedErrorMessage);
    }
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    Key? key,
    required this.message,
    required this.profile,
  }) : super(key: key);

  final Message message;
  final Profile? profile;

  @override
  Widget build(BuildContext context) {
    List<Widget> chatContents = [
      if (!message.isMine)
        CircleAvatar(
            child: profile == null
                ? preloader
                : ClipRRect(
                    borderRadius: BorderRadius.circular(25.0),
                    child: Image.network(
                      profile!.avatar,
                      height: 150.0,
                      width: 100.0,
                      fit: BoxFit.fill,
                      loadingBuilder: (BuildContext context, Widget child,
                          ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  )),
      const SizedBox(
          width: 9), //Distância entre icone de perfil e caixa de dialogo
      Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 6, //Altura da caixa de diálogo
            horizontal: 10, //Largura da caixa de diálogo
          ),
          decoration: BoxDecoration(
            color: message.isMine
                ? Theme.of(context).primaryColor
                : Colors.blueGrey,
            borderRadius: BorderRadius.circular(
                10), //Quão redondo as bordas da caixa de diálogo são
          ),
          child: Text(message.content),
        ),
      ),
      const SizedBox(
          width: 10), //Distância entre caixa de diálogo e hora de envio
      Text(format(message.createdAt, locale: 'en_short')),
      const SizedBox(width: 30),
    ];

    List<Widget> chatContentsMine = [
      Text(format(message.createdAt, locale: 'en_short')),
      const SizedBox(
          width: 10), //Distância entre caixa de diálogo e hora de envio
      Flexible(
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 6, //Altura da caixa de diálogo
            horizontal: 10, //Largura da caixa de diálogo
          ),
          decoration: BoxDecoration(
            color: message.isMine
                ? Theme.of(context).primaryColor
                : Colors.blueGrey,
            borderRadius: BorderRadius.circular(
                10), //Quão redondo as bordas da caixa de diálogo são
          ),
          child: Text(message.content),
        ),
      ),
      const SizedBox(
          width: 10), //Distância entre icone de perfil e caixa de dialogo
      CircleAvatar(
          child: profile == null
              ? preloader
              : ClipRRect(
                  borderRadius: BorderRadius.circular(25.0),
                  child: Image.network(
                    profile!.avatar,
                    height: 150.0,
                    width: 100.0,
                    fit: BoxFit.fill,
                    loadingBuilder: (BuildContext context, Widget child,
                        ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                  ),
                )),
    ];
    return Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, //Distância da borda externa
            vertical: 5), //Distancia da caixa de diálogo adjacente
        child: Row(
          mainAxisAlignment:
              message.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: message.isMine ? chatContentsMine : chatContents,
        ));
  }
}
