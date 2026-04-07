// ConnectLive — Chat Service
// Author: Shebin S Illikkal | Shebinsillikkal@gmail.com

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ChatMessage {
  final String id, senderId, senderName, content, type;
  final DateTime timestamp;
  final String? mediaUrl, replyToId;
  final Map<String, List<String>> reactions;

  ChatMessage({required this.id, required this.senderId, required this.senderName,
    required this.content, required this.type, required this.timestamp,
    this.mediaUrl, this.replyToId, this.reactions = const {}});

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id, senderId: d['senderId'], senderName: d['senderName'],
      content: d['content'] ?? '', type: d['type'] ?? 'text',
      timestamp: (d['timestamp'] as Timestamp).toDate(),
      mediaUrl: d['mediaUrl'], replyToId: d['replyToId'],
      reactions: Map<String, List<String>>.from(
        (d['reactions'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, List<String>.from(v)))),
    );
  }
}

class ChatService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;

  Stream<List<ChatMessage>> getMessages(String groupId, {int limit = 50}) {
    return _db.collection('groups').doc(groupId).collection('messages')
      .orderBy('timestamp', descending: true).limit(limit)
      .snapshots()
      .map((s) => s.docs.map(ChatMessage.fromFirestore).toList());
  }

  Future<void> sendMessage(String groupId, String content, {String type = 'text', String? replyToId}) async {
    final user = _auth.currentUser!;
    final batch = _db.batch();
    final msgRef = _db.collection('groups').doc(groupId).collection('messages').doc();
    batch.set(msgRef, {
      'senderId': user.uid, 'senderName': user.displayName,
      'content': content, 'type': type, 'replyToId': replyToId,
      'timestamp': FieldValue.serverTimestamp(), 'reactions': {},
    });
    batch.update(_db.collection('groups').doc(groupId), {
      'lastMessage': content, 'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': user.uid,
    });
    await batch.commit();
  }

  Future<void> addReaction(String groupId, String messageId, String emoji) async {
    final uid = _auth.currentUser!.uid;
    await _db.collection('groups').doc(groupId).collection('messages').doc(messageId).update({
      'reactions.'+emoji: FieldValue.arrayUnion([uid])
    });
  }

  Future<String> uploadMedia(String groupId, File file, String type) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('chat_media/'+groupId+'/'+timestamp.toString()+'_'+type);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }
}
