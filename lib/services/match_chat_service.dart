import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config.dart';

// Real-time match chat over the backend WebSocket (ws://host/ws/chat?match=<id>).
// Mirrors the protocol in backend/chat-server.js:
//   -> {type:'identify', user:{name,img}}
//   -> {type:'message', payload:{kind:'text'|'sticker'|'image', text, sticker, image}}
//   -> {type:'react', messageId}
//   <- {type:'connected'|'identified'|'message'|'system'|'like_update'|'typing'|'online_count'|...}
class MatchChatService {
  final String matchId;
  final String? userName;
  final String? userImg;

  WebSocketChannel? _channel;
  final StreamController<ChatEvent> _events = StreamController.broadcast();
  final List<ChatMessage> _messages = [];
  int _onlineCount = 0;
  bool _connected = false;

  MatchChatService({required this.matchId, this.userName, this.userImg});

  Stream<ChatEvent> get stream => _events.stream;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  int get onlineCount => _onlineCount;
  bool get isConnected => _connected;

  void connect() {
    if (_connected) return;
    final wsUrl = apiBaseUrl
        .replaceFirst(RegExp(r'^https?'), 'ws')
        .replaceFirst(RegExp(r'/?$'), '') +
        '/ws/chat?match=$matchId';
    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _channel!.stream.listen(
        _onData,
        onError: (e) => _events.add(ChatEvent.error(e.toString())),
        onDone: () {
          _connected = false;
          _events.add(const ChatEvent.disconnected());
        },
      );
      _connected = true;
    } catch (e) {
      _events.add(ChatEvent.error(e.toString()));
    }
  }

  void _onData(dynamic raw) {
    try {
      final Map<String, dynamic> msg = jsonDecode(raw as String);
      final type = msg['type'] as String? ?? '';
      switch (type) {
        case 'connected':
          _onlineCount = msg['onlineCount'] ?? 0;
          final recent = msg['recentMessages'] as List? ?? [];
          for (final r in recent) {
            final m = ChatMessage.fromJson(r);
            if (m != null) _messages.add(m);
          }
          _events.add(ChatEvent.connected(msg['user'] ?? {}));
          _identify();
          break;
        case 'identified':
          break;
        case 'message':
          final m = ChatMessage.fromJson(msg);
          if (m != null) {
            _messages.add(m);
            if (_messages.length > 120) _messages.removeAt(0);
            _events.add(ChatEvent.message(m));
          }
          break;
        case 'system':
          final m = ChatMessage.fromJson(msg);
          if (m != null) {
            _messages.add(m);
            _events.add(ChatEvent.message(m));
          }
          break;
        case 'like_update':
          _applyLike(msg['messageId'], msg['likes'] ?? 0);
          break;
        case 'online_count':
          _onlineCount = msg['onlineCount'] ?? _onlineCount;
          _events.add(ChatEvent.online(_onlineCount));
          break;
        case 'typing':
          _events.add(ChatEvent.typing(
            msg['userName'] ?? '',
            msg['isTyping'] == true,
          ));
          break;
        default:
          break;
      }
    } catch (_) {
      // ignore malformed frames
    }
  }

  void _identify() {
    if (userName != null || userImg != null) {
      sendRaw({
        'type': 'identify',
        'user': {'name': userName, 'img': userImg},
      });
    }
  }

  void _applyLike(String? id, int likes) {
    if (id == null) return;
    final idx = _messages.indexWhere((m) => m.id == id);
    if (idx != -1) {
      _messages[idx] = _messages[idx].copyWith(likes: likes);
      _events.add(ChatEvent.like(id, likes));
    }
  }

  void sendText(String text) {
    sendRaw({
      'type': 'message',
      'payload': {'kind': 'text', 'text': text},
    });
  }

  void sendSticker(String sticker) {
    sendRaw({
      'type': 'message',
      'payload': {'kind': 'sticker', 'sticker': sticker},
    });
  }

  void react(String messageId) {
    sendRaw({'type': 'react', 'messageId': messageId});
  }

  void sendTyping(bool isTyping) {
    sendRaw({'type': 'typing', 'isTyping': isTyping});
  }

  void sendRaw(Map<String, dynamic> payload) {
    try {
      _channel?.sink.add(jsonEncode(payload));
    } catch (_) {}
  }

  void dispose() {
    try {
      _channel?.sink.close();
    } catch (_) {}
    _events.close();
  }
}

class ChatMessage {
  final String type; // 'message' | 'system'
  final String id;
  final String? text;
  final String? sticker;
  final String? image;
  final String? userName;
  final String? userImg;
  final int likes;
  final int time;

  ChatMessage({
    required this.type,
    required this.id,
    this.text,
    this.sticker,
    this.image,
    this.userName,
    this.userImg,
    this.likes = 0,
    required this.time,
  });

  bool get isSystem => type == 'system';

  ChatMessage copyWith({int? likes}) =>
      ChatMessage(
        type: type,
        id: id,
        text: text,
        sticker: sticker,
        image: image,
        userName: userName,
        userImg: userImg,
        likes: likes ?? this.likes,
        time: time,
      );

  static ChatMessage? fromJson(Map<String, dynamic> m) {
    final type = m['type'] as String? ?? 'message';
    final id = m['id']?.toString() ??
        'msg_${DateTime.now().millisecondsSinceEpoch}_${m.hashCode}';
    if (type == 'system') {
      return ChatMessage(
        type: 'system',
        id: id,
        text: m['text']?.toString(),
        userName: m['user'] is Map ? (m['user']['name']?.toString()) : null,
        time: m['time'] is int ? m['time'] : DateTime.now().millisecondsSinceEpoch,
      );
    }
    final user = m['user'] is Map ? m['user'] as Map : <String, dynamic>{};
    return ChatMessage(
      type: 'message',
      id: id,
      text: m['text']?.toString(),
      sticker: m['sticker']?.toString(),
      image: m['image']?.toString(),
      userName: user['name']?.toString(),
      userImg: user['img']?.toString(),
      likes: m['likes'] is int ? m['likes'] : 0,
      time: m['time'] is int ? m['time'] : DateTime.now().millisecondsSinceEpoch,
    );
  }
}

class ChatEvent {
  final String kind; // connected | message | like | online | typing | error | disconnected
  final dynamic data;
  const ChatEvent._(this.kind, this.data);
  factory ChatEvent.connected(dynamic user) => ChatEvent._('connected', user);
  factory ChatEvent.message(ChatMessage m) => ChatEvent._('message', m);
  factory ChatEvent.like(String id, int likes) =>
      ChatEvent._('like', {'id': id, 'likes': likes});
  factory ChatEvent.online(int count) => ChatEvent._('online', count);
  factory ChatEvent.typing(String name, bool isTyping) =>
      ChatEvent._('typing', {'name': name, 'isTyping': isTyping});
  factory ChatEvent.error(String e) => ChatEvent._('error', e);
  const ChatEvent.disconnected() : this._('disconnected', null);
}
