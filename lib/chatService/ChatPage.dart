import 'package:flutter/material.dart';
import 'SocketService.dart';

class ChatPage extends StatefulWidget {
  final String userId;
  final String receiverId;

  ChatPage({required this.userId, required this.receiverId});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late SocketService _socketService;
  List<Map<String, String>> _messages = [];
  TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _socketService = SocketService();
    _socketService.connect(widget.userId);

    // Listen for incoming chat history
    _socketService.listenForChatHistory((data) {
      setState(() {
        _messages = List<Map<String, String>>.from(data.map((msg) => {
          'senderId': msg['senderId'],
          'message': msg['message']
        }));
      });
    });

    // Request chat history on connection
    _socketService.getChatHistory(widget.receiverId);

    // Listen for real-time messages
    _socketService.listenForMessages((data) {
      setState(() {
        _messages.add({
          'senderId': data['senderId'],
          'message': data['message']
        });
      });
    });
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      _socketService.sendMessage(widget.receiverId, _controller.text);
      setState(() {
        _messages.add({'senderId': 'Me', 'message': _controller.text});
      });
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Text("${message['senderId']}: ${message['message']}"),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter your message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
