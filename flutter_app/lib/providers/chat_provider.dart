import 'package:flutter/foundation.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';

class ChatProvider extends ChangeNotifier {
  List<Chat> _chats = [];
  List<User> _users = [];
  final Map<String, List<Message>> _messages = {};
  final Map<String, bool> _typingStatus = {};
  bool _isLoading = false;
  bool _isLoadingUsers = false;
  String? _error;

  List<Chat> get chats => List.unmodifiable(_chats);
  List<User> get users => List.unmodifiable(_users);
  Map<String, List<Message>> get messages => Map.unmodifiable(_messages);
  Map<String, bool> get typingStatus => Map.unmodifiable(_typingStatus);
  bool get isLoading => _isLoading;
  bool get isLoadingUsers => _isLoadingUsers;
  String? get error => _error;

  int get totalUnreadCount =>
      _chats.fold(0, (sum, chat) => sum + chat.unreadCount);

  final _api = ApiService();
  final _socket = SocketService();

  void initSocketListeners() {
    _socket.onNewMessage((data) {
      if (data is Map<String, dynamic>) {
        handleNewMessage(data);
      }
    });

    _socket.onTyping((data) {
      if (data is Map<String, dynamic>) {
        handleTyping(data);
      }
    });

    _socket.onMessageStatus((data) {
      if (data is Map<String, dynamic>) {
        handleMessageStatus(data);
      }
    });

    _socket.onUserStatus((data) {
      if (data is Map<String, dynamic>) {
        _handleUserStatus(data);
      }
    });
  }

  void _handleUserStatus(Map<String, dynamic> data) {
    final userId = data['userId']?.toString();
    final online = data['online'] as bool? ?? false;
    if (userId == null) return;

    bool changed = false;
    for (int i = 0; i < _chats.length; i++) {
      final updatedParticipants = _chats[i].participants.map((u) {
        if (u.id == userId) {
          changed = true;
          return u.copyWith(online: online);
        }
        return u;
      }).toList();
      if (changed) {
        _chats[i] = _chats[i].copyWith(participants: updatedParticipants);
      }
    }
    if (changed) notifyListeners();
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _users = [];
      notifyListeners();
      return;
    }
    _isLoadingUsers = true;
    notifyListeners();
    try {
      final encoded = Uri.encodeComponent(query.trim());
      final data = await _api.get('/users?q=$encoded');
      final list = data is List ? data : (data['users'] as List<dynamic>? ?? []);
      _users = list
          .whereType<Map<String, dynamic>>()
          .map((u) => User.fromJson(u))
          .toList();
    } catch (e) {
      _users = [];
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  Future<void> loadChats() async {
    _setLoading(true);
    _setError(null);
    try {
      final data = await _api.get('/chats');
      final chatList = data is List
          ? data
          : (data['chats'] as List<dynamic>? ?? []);
      _chats = chatList
          .whereType<Map<String, dynamic>>()
          .map((c) => Chat.fromJson(c))
          .toList();
      _chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMessages(String chatId) async {
    _setLoading(true);
    _setError(null);
    try {
      final data = await _api.get('/chats/$chatId/messages');
      final messageList = data is List
          ? data
          : (data['messages'] as List<dynamic>? ?? []);
      final msgs = messageList
          .whereType<Map<String, dynamic>>()
          .map((m) => Message.fromJson(m))
          .toList();
      msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      _messages[chatId] = msgs;
      _socket.joinChat(chatId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<Message?> sendMessage(String chatId, String text) async {
    try {
      final data = await _api.post('/chats/$chatId/messages', {'text': text});
      if (data != null) {
        final msgData = data['message'] ?? data;
        final message = Message.fromJson(msgData as Map<String, dynamic>);
        _addOrUpdateMessage(chatId, message);
        _updateChatLastMessage(chatId, message);
        return message;
      }
    } catch (e) {
      // Also try via socket
      _socket.sendMessage(chatId, text);
    }
    return null;
  }

  Future<Chat?> createChat(String participantId) async {
    try {
      final data = await _api.post('/chats', {'participantId': participantId});
      if (data != null) {
        final chatData = data['chat'] ?? data;
        final chat = Chat.fromJson(chatData as Map<String, dynamic>);
        final existingIndex = _chats.indexWhere((c) => c.id == chat.id);
        if (existingIndex == -1) {
          _chats.insert(0, chat);
        }
        notifyListeners();
        return chat;
      }
    } catch (e) {
      _setError(e.toString());
    }
    return null;
  }

  void handleNewMessage(Map<String, dynamic> data) {
    final chatId = data['chatId']?.toString() ?? data['chat']?.toString();
    if (chatId == null) return;

    try {
      final message = Message.fromJson(data);
      _addOrUpdateMessage(chatId, message);
      _updateChatLastMessage(chatId, message);
    } catch (_) {
      // Invalid message data
    }
  }

  void handleTyping(Map<String, dynamic> data) {
    final chatId = data['chatId']?.toString();
    final isTyping = data['isTyping'] as bool? ?? false;
    if (chatId == null) return;
    _typingStatus[chatId] = isTyping;
    notifyListeners();
  }

  void handleMessageStatus(Map<String, dynamic> data) {
    final chatId = data['chatId']?.toString();
    final messageId = data['messageId']?.toString();
    final status = data['status']?.toString();
    if (chatId == null || messageId == null || status == null) return;

    final chatMessages = _messages[chatId];
    if (chatMessages == null) return;

    final index = chatMessages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[chatId]![index] = chatMessages[index].copyWith(status: status);
      notifyListeners();
    }
  }

  void _addOrUpdateMessage(String chatId, Message message) {
    final chatMessages = _messages[chatId] ?? [];
    final index = chatMessages.indexWhere((m) => m.id == message.id);
    if (index == -1) {
      _messages[chatId] = [...chatMessages, message];
    } else {
      final updated = [...chatMessages];
      updated[index] = message;
      _messages[chatId] = updated;
    }
    notifyListeners();
  }

  void _updateChatLastMessage(String chatId, Message message) {
    final index = _chats.indexWhere((c) => c.id == chatId);
    if (index != -1) {
      final updated = _chats[index].copyWith(
        lastMessage: message,
        updatedAt: message.createdAt,
      );
      _chats = [..._chats];
      _chats[index] = updated;
      _chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      notifyListeners();
    }
  }

  List<Message> getMessagesForChat(String chatId) {
    return _messages[chatId] ?? [];
  }

  bool isTypingInChat(String chatId) {
    return _typingStatus[chatId] ?? false;
  }

  void leaveChat(String chatId) {
    _socket.leaveChat(chatId);
  }

  void sendTypingStatus(String chatId, bool isTyping) {
    _socket.sendTyping(chatId, isTyping);
  }

  void markMessageRead(String chatId, String messageId) {
    _socket.markRead(chatId, messageId);
  }

  List<Chat> searchChats(String query, String currentUserId) {
    if (query.isEmpty) return _chats;
    final lower = query.toLowerCase();
    return _chats.where((c) {
      final name = c.displayName(currentUserId).toLowerCase();
      final lastMsg = c.lastMessage?.text.toLowerCase() ?? '';
      return name.contains(lower) || lastMsg.contains(lower);
    }).toList();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _chats = [];
    _messages.clear();
    _typingStatus.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
