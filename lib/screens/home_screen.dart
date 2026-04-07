import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import 'chat_room_screen.dart';

/// ConnectLive — Home Screen
/// Author: Shebin S Illikkal | Shebinsillikkal@gmail.com

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final chat = context.watch<ChatService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('ConnectLive', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: auth.signOut),
        ],
      ),
      body: StreamBuilder(
        stream: chat.getRooms(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final rooms = snapshot.data!.docs;
          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (ctx, i) {
              final room = rooms[i].data() as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF6366F1),
                  child: Text(room['name'][0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                ),
                title: Text(room['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text(room['lastMessage'] ?? 'No messages yet',
                  style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis),
                trailing: room['unread'] != null && room['unread'] > 0
                  ? Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                      child: Text('${room["unread"]}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    )
                  : null,
                onTap: () => Navigator.push(ctx, MaterialPageRoute(
                  builder: (_) => ChatRoomScreen(roomId: rooms[i].id, roomName: room['name']))),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6366F1),
        onPressed: () => _showCreateRoom(context, chat),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showCreateRoom(BuildContext context, ChatService chat) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('New Room', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Room name', hintStyle: TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () { chat.createRoom(controller.text); Navigator.pop(context); },
            child: const Text('Create', style: TextStyle(color: Color(0xFF6366F1))),
          ),
        ],
      ),
    );
  }
}
