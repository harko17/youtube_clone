import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube/main.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String currentUserID;
  final String otherUserID;
  final String otherUserDp;
  final String otherUserName;
  final String currentUserName;
  final String currentUserDp;

  ChatPage({required this.currentUserID, required this.otherUserID,required this.otherUserDp,required this.otherUserName,required this.currentUserName,required this.currentUserDp});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    listenForNewMessages();
    //listenForNewMessages();
  }
  TextEditingController _controller = TextEditingController();

  Future<void> _sendMessage(String messageContent) async {
    if (messageContent.isNotEmpty) {
      final response = await Supabase.instance.client
          .from('messages')
          .insert({
        'sender_id': widget.currentUserID,
        'receiver_id': widget.otherUserID,
        'content': messageContent,
        'created_at': DateTime.now().toIso8601String(),
      }).whenComplete(() => _loadMessages());

      if (response.error != null) {
        print('Error sending message: ${response.error!.message}');
      } else {
        _controller.clear();
        listenForNewMessages();

      }
    }
  }

  void listenForNewMessages() {
    final supabase = Supabase.instance.client;

    final stream = supabase
        .from('messages') // Specify the table to listen to
        .stream(primaryKey: ['id']) // Provide the primary key column(s)
        .eq('receiver_id', widget.currentUserID) // Optional: filter by receiver_id
        .listen((List<Map<String, dynamic>> data) {
      setState(() {
        messages.addAll(data);
        _loadMessages();// Add the new messages to your list
      });
    });
  }


  Future<void> _loadMessages() async {
    try {
      final fetchedMessages =
          await fetchMessages(widget.currentUserID, widget.otherUserID);
      setState(() {
        messages = fetchedMessages;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<List<Map<String, dynamic>>> fetchMessages(
      String currentUserID, String otherUserID) async {
    final response = await Supabase.instance.client
        .from('messages')
        .select()
        .or('and(sender_id.eq.$currentUserID,receiver_id.eq.$otherUserID),and(sender_id.eq.$otherUserID,receiver_id.eq.$currentUserID)')
        .order('created_at', ascending: false);

    if (response != null) {
      return response as List<Map<String, dynamic>>;
    } else {
      throw Exception('Failed to fetch messages: ${response}');
    }
  }
  void _showDpPopup() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop(); // Close the dialog on tap
            },
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: 300, // Adjust the maximum height
                maxWidth: 300,  // Adjust the maximum width
              ),
              child: Image.network(
                widget.otherUserDp,
                fit: BoxFit.contain, // Ensure the image fits within the box
              ),
            ),
          ),
        );
      },
    );
  }

  String formatDateTime(String isoDateTime) {
    DateTime dateTime = DateTime.parse(isoDateTime);
    return DateFormat('hh:mm a').format(dateTime); // Format as needed
  }
  void _showDeleteConfirmation(int messageId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this message?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deleteMessage(messageId);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
  void _deleteMessage(int messageId) async {
    final response = await Supabase.instance.client
        .from('messages')
        .delete()
        .match({'id': messageId}).whenComplete(() => _loadMessages());

    if (response.error != null) {
      print('Error deleting message: ${response.error!.message}');
    } else {
      setState(() {
        messages.removeWhere((message) => message['id'] == messageId);
        listenForNewMessages();
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            GestureDetector(
              onTap: _showDpPopup,
              child: CircleAvatar(
                backgroundImage: NetworkImage(widget.otherUserDp),
              ),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Online', // Placeholder for online status
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.call),
            onPressed: () {
              // Call functionality here
              print('Call button pressed');
            },
          ),
          IconButton(
            icon: Icon(Icons.videocam),
            onPressed: () {
              // Video call functionality here
              print('Video call button pressed');
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {
              // More options functionality here
              print('More button pressed');
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [

            Expanded(

              child: ListView.builder(
                reverse: true,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  bool isCurrentUser =
                      message['sender_id'] == widget.currentUserID;
                  return ListTile(
                    title: Align(
                      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: (){
                          if (isCurrentUser) {
                            _showDeleteConfirmation(message['id']);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isCurrentUser ? Colors.purple : Colors.blue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [

                              Text(
                                message['content'],
                                style: TextStyle(color: Colors.white),
                              ),
                              SizedBox(height: 4),
                              Text(
                                formatDateTime(message['created_at']),
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

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

                      decoration:
                          InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[100],
                              border: OutlineInputBorder(

                                borderSide: BorderSide.none,
                              ),
                              hintText: 'Type your message...'),

                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      _sendMessage(_controller.text);
                      setState(() {
                        _controller.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
