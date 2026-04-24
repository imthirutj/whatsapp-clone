import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String token) {
    if (_socket != null && _socket!.connected) return;

    _socket = io.io(
      kSocketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _socket!.emit('authenticate', {'token': token});
    });

    _socket!.onDisconnect((_) {
      // Handle disconnect
    });

    _socket!.onConnectError((data) {
      // Handle connection error
    });

    _socket!.onError((data) {
      // Handle error
    });
  }

  void joinChat(String chatId) {
    _socket?.emit('join_chat', {'chatId': chatId});
  }

  void leaveChat(String chatId) {
    _socket?.emit('leave_chat', {'chatId': chatId});
  }

  void sendMessage(String chatId, String text) {
    _socket?.emit('send_message', {'chatId': chatId, 'text': text});
  }

  void sendTyping(String chatId, bool isTyping) {
    _socket?.emit('typing', {'chatId': chatId, 'isTyping': isTyping});
  }

  void sendLiveTyping(String chatId, String text) {
    _socket?.emit('live_typing', {'chatId': chatId, 'text': text});
  }

  void sendMessageDelivered(String messageId, String chatId) {
    _socket?.emit('message_delivered', {'messageId': messageId, 'chatId': chatId});
  }

  void markRead(String chatId, String messageId) {
    _socket?.emit('message_read', {'chatId': chatId, 'messageId': messageId});
  }

  void onNewMessage(Function(dynamic) callback) {
    _socket?.on('new_message', callback);
  }

  void offNewMessage() {
    _socket?.off('new_message');
  }

  void onTyping(Function(dynamic) callback) {
    _socket?.on('typing', callback);
  }

  void offTyping() {
    _socket?.off('typing');
  }

  void onLiveTyping(Function(dynamic) callback) {
    _socket?.on('live_typing', callback);
  }

  void offLiveTyping() {
    _socket?.off('live_typing');
  }

  void onMessageStatus(Function(dynamic) callback) {
    _socket?.on('message_status', callback);
  }

  void offMessageStatus() {
    _socket?.off('message_status');
  }

  void onUserStatus(Function(dynamic) callback) {
    _socket?.on('user_status', callback);
  }

  void offUserStatus() {
    _socket?.off('user_status');
  }

  void onMessagesRead(Function(dynamic) callback) {
    _socket?.on('messages_read', callback);
  }

  void offMessagesRead() {
    _socket?.off('messages_read');
  }

  void removeAllListeners() {
    _socket?.clearListeners();
  }

  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
}
