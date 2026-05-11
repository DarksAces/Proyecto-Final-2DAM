import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../theme/app_theme.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late IO.Socket socket;
  List<Map<String, dynamic>> messages = [
    {
      "username": "UsuarioFlutter",
      "message": "¡Hola a todos!",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 5)),
    },
    {
      "username": "Alex AR",
      "message": "¡Todo bien! ¿Alguien para ir a explorar?",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 4)),
    }
  ];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String myUsername =
      "UsuarioFlutter"; // O el nombre del usuario logueado

  @override
  void initState() {
    super.initState();
    initSocket();
  }

  void initSocket() {
    socket = IO.io('https://aura-bmqy.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket.connect();
    socket.onConnect((_) {
      print('Conectado al servidor de sockets');
    });

    socket.on('receive_message', (data) {
      if (mounted) {
        if (data["username"] == myUsername)
          return; // Evitar duplicado si ya lo mostramos
        setState(() {
          messages.insert(0, {
            "username": data["username"],
            "message": data["message"],
            "timestamp": DateTime.now(),
          });
        });
      }
    });
    socket.onDisconnect((_) => print('Desconectado'));
  }

  void sendMessage() {
    String text = _controller.text.trim();
    if (text.isNotEmpty) {
      // Mostrar el mensaje inmediatamente de forma local
      setState(() {
        messages.insert(0, {
          'username': myUsername,
          'message': text,
          'timestamp': DateTime.now(),
        });
      });

      socket.emit('send_message', {
        'username': myUsername,
        'message': text,
      });
      _controller.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // En un ListView invertido, 0.0 es el final (abajo)
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.arteRed,
                  child: Icon(Icons.people, color: Colors.white),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2)),
                  ),
                )
              ],
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Chat Comunitario",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            )
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.black),
              onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse:
                  true, // Esto hace que los mensajes salgan de abajo hacia arriba y no los tape el teclado
              padding: const EdgeInsets.all(20),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                bool isMe = msg['username'] == myUsername;
                String time =
                    DateFormat('hh:mm a').format(msg['timestamp'] as DateTime);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (!isMe)
                        Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 4),
                          child: Text(
                            msg['username'],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      _MessageBubble(
                        isMe: isMe,
                        message: msg['message'],
                        time: time,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade100))),
            child: SafeArea(
              // Be careful with bottom safe area
              child: Row(
                children: [
                  CircleAvatar(
                      backgroundColor: Colors.grey.shade100,
                      child: const Icon(Icons.add, color: Colors.black)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                            hintText: "Escribe un mensaje...",
                            border: InputBorder.none,
                            icon: Icon(Icons.sticky_note_2_outlined,
                                color: Colors.grey, size: 20)),
                        onSubmitted: (_) => sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                          color: AppTheme.arteRed,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Color(0x33FF0000),
                                blurRadius: 10,
                                offset: Offset(0, 4))
                          ]),
                      child:
                          const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final bool isMe;
  final String message;
  final String time;
  final bool isRead;

  const _MessageBubble({
    required this.isMe,
    required this.message,
    required this.time,
    this.isRead = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
                color: isMe ? AppTheme.arteRed : Colors.white,
                border: isMe ? null : Border.all(color: Colors.grey.shade100),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(20),
                ),
                boxShadow: isMe
                    ? [
                        BoxShadow(
                            color: AppTheme.arteRed.withAlpha(50),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ]
                    : null),
            child: Text(
              message,
              style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                  fontSize: 15,
                  height: 1.4),
            ),
          ),
          if (time.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(time,
                      style:
                          TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                  if (isMe && isRead) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all,
                        size: 12, color: AppTheme.arteRed)
                  ]
                ],
              ),
            )
        ],
      ),
    );
  }
}
