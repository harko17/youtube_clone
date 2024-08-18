import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? socket;

  void connect(String userId) {
    socket = IO.io(
      'http://localhost:3000', // Replace with your backend URL
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setQuery({'userId': userId})
          .build(),
    );

    socket?.onConnect((_) {
      print('Connected as user $userId');
    });
  }

  void getChatHistory(String receiverId) {
    socket?.emit('getChatHistory', {'userId': socket?.id, 'receiverId': receiverId});
  }

  void listenForChatHistory(Function onHistoryReceived) {
    socket?.on('chatHistory', (data) {
      onHistoryReceived(data);
    });
  }

  void sendMessage(String receiverId, String message) {
    socket?.emit('sendMessage', {
      'senderId': socket?.id,
      'receiverId': receiverId,
      'message': message,
    });
  }

  void listenForMessages(Function onMessageReceived) {
    socket?.on('receiveMessage', (data) {
      onMessageReceived(data);
    });
  }

  void disconnect() {
    socket?.disconnect();
  }
}
