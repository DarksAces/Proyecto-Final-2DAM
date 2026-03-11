import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

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
                  backgroundImage:
                      NetworkImage("https://i.pravatar.cc/150?img=11"),
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
                Text("Alex Designer",
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                Text("EN LÍNEA",
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
        actions: [
          // IconButton(icon: const Icon(Icons.videocam, color: Colors.black), onPressed: (){}), // REMOVED as per request
          IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.black),
              onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text("HOY",
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 20),

                // Received Text
                const _MessageBubble(
                  isMe: false,
                  message:
                      "¡Oye! Tienes que ver lo que acabo de encontrar con el escáner Jovi AR en el centro. 🎨",
                  time: "10:42 AM",
                ),

                // Received Image
                const _ImageBubble(
                  imageUrl:
                      "https://images.unsplash.com/photo-1517713982677-4b66332f98de?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=60",
                  label: "Mural Escondido – Calle Mayor",
                  description:
                      "Es un mural interactivo que solo aparece si usas los pinceles virtuales.",
                ),

                // Sent Text
                const _MessageBubble(
                  isMe: true,
                  message:
                      "¡Increíble! Justo estoy por la zona. ¿Me puedes pasar la ubicación exacta? 📍",
                  time: "10:45 AM",
                  isRead: true,
                ),

                // Typing Indicator
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                        bottomLeft: Radius.circular(0),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Dot(),
                        const SizedBox(width: 4),
                        _Dot(),
                        const SizedBox(width: 4),
                        _Dot()
                      ],
                    ),
                  ),
                )
              ],
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
                      child: const TextField(
                        decoration: InputDecoration(
                            hintText: "Escribe un mensaje...",
                            border: InputBorder.none,
                            icon: Icon(Icons.sticky_note_2_outlined,
                                color: Colors.grey, size: 20)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                        color: AppTheme.joviRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Color(0x33FF0000),
                              blurRadius: 10,
                              offset: Offset(0, 4))
                        ]),
                    child:
                        const Icon(Icons.send, color: Colors.white, size: 20),
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
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
                color: isMe
                    ? AppTheme.joviRed
                    : Colors.white, // White for received
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
                            color: AppTheme.joviRed.withAlpha(50),
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
                        size: 12, color: AppTheme.joviRed)
                  ]
                ],
              ),
            )
        ],
      ),
    );
  }
}

class _ImageBubble extends StatelessWidget {
  final String imageUrl;
  final String label;
  final String description;

  const _ImageBubble({
    required this.imageUrl,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.zero,
          ),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(imageUrl,
                      height: 180, width: double.infinity, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppTheme.joviRed,
                        borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      children: [
                        Icon(Icons.center_focus_strong,
                            color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text("JOVI AR",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold))
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                          Colors.black.withAlpha(200),
                          Colors.transparent
                        ])),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(label,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(description,
                  style: const TextStyle(color: Colors.black, fontSize: 14)),
            )
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration:
          BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle),
    );
  }
}
