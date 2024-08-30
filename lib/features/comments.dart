import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube/home%20screen/profile.dart';
import '../main.dart';

int currVideoId = 0;
List currVideoCommentId = [];

class CommentSectionScreen extends StatefulWidget {
  final int id;
  final List commentId;

  CommentSectionScreen({
    required this.id,
    required this.commentId,
  });

  @override
  _CommentSectionScreenState createState() => _CommentSectionScreenState();
}

class _CommentSectionScreenState extends State<CommentSectionScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<Comment> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchComments();
  }

  Future<void> fetchComments() async {
    final response = await Supabase.instance.client
        .from('comments')
        .select()
        .eq('videoId', widget.id)
        .eq('isReply', false);

    if (response.isNotEmpty) {
      setState(() {
        _comments = (response as List<dynamic>)
            .map((json) => Comment.fromJson(json))
            .toList();
        _isLoading = false;
      });
    }
  }

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    // Perform async operations first
    final List<Map<String, dynamic>> data =
        await supabase.from("comments").insert([
      {
        'userName': currUserName,
        'userProfilePicUrl': currUserDp.toString(),
        'commentText': _commentController.text.trim(),
        'likeCount': 0,
        'dislikeCount': 0,
        'videoId': widget.id,
        'isReply': false,
      }
    ]).select();

    List commentIds = widget.commentId;
    commentIds.add(data[0]['id']);

    await supabase.from("videos").update({
      'commentId': commentIds,
    }).eq('id', widget.id);

    // Add the new comment to the state and clear the input field
    setState(() {
      _comments.add(Comment.fromJson(data[0]));
      _commentController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Text("Comments",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Spacer(),
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.close, size: 30),
              ),
            ],
          ),
        ),
        _isLoading
            ? Center(child: CircularProgressIndicator())
            : Expanded(
                child: CommentsSection(comments: _comments),
              ),
        Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: CommentInputField(
            controller: _commentController,
            onSend: _addComment,
            isReply: false,
          ),
        ),
      ],
    );
  }
}

class CommentsSection extends StatefulWidget {
  final List<Comment> comments;

  CommentsSection({required this.comments});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: widget.comments.length,
        itemBuilder: (context, index) {
          return CommentWidget(
            comment: widget.comments[index],
            showR: true,
          );
        },
      ),
    );
  }
}

class CommentInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  bool isReply;

  CommentInputField(
      {required this.controller, required this.onSend, required this.isReply});

  @override
  State<CommentInputField> createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<CommentInputField> {
  @override
  Widget build(BuildContext context) {
    if (supabase.auth.currentUser != null)
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: widget.controller,
                decoration: InputDecoration(
                  hintText: widget.isReply
                      ? 'Add a reply...'
                      : 'Add a public comment...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: widget.onSend,
            ),
          ],
        ),
      );
    return Text("");
  }
}

class CommentWidget extends StatefulWidget {
  final Comment comment;
  bool showR = true;

  CommentWidget({required this.comment, required this.showR});

  @override
  State<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  Future<List<Comment>> fetchCommentsById(int n) async {
    final response =
        await Supabase.instance.client.from('comments').select().eq('id', n);
    ;

    if (response.isEmpty) {
      print('Error fetching users: ${response}');
      return [];
    }

    final List<dynamic> data = response;

    return data.map((json) => Comment.fromJson(json)).toList();
  }

  void _openReplies() {
    showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0.0)),
      ),
      context: (context),
      builder: (context) => SelectedCommentScreen(comment: widget.comment),
    );
  }

  @override
  Widget build(BuildContext context) {
    int currTime = DateTime.now()
        .difference(DateTime.parse(widget.comment.created_at))
        .inDays;
    String toDisplay = "";
    if (currTime < 1) {
      toDisplay = "Few hours ago";
    } else if (currTime < 7) {
      toDisplay = "$currTime days ago";
    } else if (currTime < 30) {
      toDisplay = "${(currTime / 7).toInt()} weeks ago";
    } else if (currTime < 365) {
      toDisplay = "${(currTime / 30).toInt()} months ago";
    } else {
      toDisplay = "${(currTime / 365).toInt()} years ago";
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundImage:
                NetworkImage(widget.comment.userProfilePicUrl.toString()),
          ),
          title: Row(
            children: [
              Text(
                widget.comment.userName,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  toDisplay,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
          subtitle: Text(widget.comment.commentText),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 72.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.thumb_up_alt_outlined),
                onPressed: () {},
              ),
              Text(widget.comment.likeCount.toString()),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.thumb_down_alt_outlined),
                onPressed: () {},
              ),
              Text(widget.comment.dislikeCount.toString()),
              SizedBox(width: 16),
              if (widget.showR)
                TextButton(
                  onPressed: _openReplies,
                  child: Text('Reply'),
                ),
            ],
          ),
        ),
        if (widget.showR == true &&
            widget.comment.replies.isNotEmpty &&
            widget.comment.replies.length != 0)
          Padding(
            padding: const EdgeInsets.only(left: 72.0),
            child: TextButton(
                onPressed: _openReplies,
                child: Text("${widget.comment.replies.length} Replies")),
          ),
      ],
    );
  }
}

class Comment {
  final String userName;
  final String userProfilePicUrl;
  final String commentText;
  final String timeAgo;
  final int likeCount;
  final int dislikeCount;
  final List replies;
  final String created_at;
  final int id;

  Comment(
      {
      /*this.userName="",
     this.userProfilePicUrl="",
     this.commentText="",
     this.timeAgo="",
     this.likeCount=0,
     this.dislikeCount=0,
     this.replies=const [],*/

      required this.userName,
      required this.userProfilePicUrl,
      required this.commentText,
      required this.timeAgo,
      required this.likeCount,
      required this.dislikeCount,
      required this.replies,
      required this.created_at,
      required this.id});

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      userName: json['userName'] == null ? '' : json['userName'],
      userProfilePicUrl:
          json['userProfilePicUrl'] == null ? '' : json['userProfilePicUrl'],
      commentText: json['commentText'] == null ? '' : json['commentText'],
      timeAgo: json['created_at'] == null ? '' : json['created_at'],
      likeCount: json['likeCount'] == null ? 15 : json['likeCount'],
      dislikeCount: json['dislikeCount'] == null ? 2 : json['dislikeCount'],
      replies: json['replies'] == null ? [] : json['replies'],
      created_at:
          json['created_at'] == null ? DateTime.now() : json['created_at'],
      id: json['id'],
    );
  }
}

class SelectedCommentScreen extends StatefulWidget {
  final Comment comment;

  SelectedCommentScreen({required this.comment});

  @override
  State<SelectedCommentScreen> createState() => _SelectedCommentScreenState();
}

class _SelectedCommentScreenState extends State<SelectedCommentScreen> {
  Future<List<Comment>> fetchCommentsById(int n) async {
    final response =
        await Supabase.instance.client.from('comments').select().eq('id', n).order('created_at', ascending: true);;
    ;

    if (response.isEmpty) {
      print('Error fetching users: ${response}');
      return [];
    }

    final List<dynamic> data = response;

    return data.map((json) => Comment.fromJson(json)).toList();
  }

  final TextEditingController _commentController = TextEditingController();

  void _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    // Perform async operations first
    final List<Map<String, dynamic>> data =
        await supabase.from("comments").insert([
      {
        'userName': currUserName,
        'userProfilePicUrl': currUserDp.toString(),
        'commentText': _commentController.text.trim().toString(),
        'likeCount': 0,
        'dislikeCount': 0,
        'videoId': currVideoId,
        'isReply': true,
      }
    ]).select();

    _commentController.clear();

    // Modify the replies list
    List replies = widget.comment.replies;
    replies.add(data[0]['id'].toString());

    await supabase.from("comments").update({
      'replies': replies,
    }).eq('id', widget.comment.id);

    // Now update the UI state
    setState(() {
      // You can add the new reply to the UI list here if needed
      //_replies.add(...); // Uncomment this line if you want to manually add the reply to your list
    });

    print(data[0]['id']);
  }

  @override
  Widget build(BuildContext context) {
    Future<List<Comment>> fetchComments() async {
      final response = await Supabase.instance.client
          .from('comments')
          .select()
          .eq('videoId', currVideoId).order('created_at', ascending: true);;
      ;

      if (response.isEmpty) {
        print('Error fetching users: ${response}');
        return [];
      }

      final List<dynamic> data = response;

      return data.map((json) => Comment.fromJson(json)).toList();
    }

    Future<List<Comment>> _myData = fetchComments();
    return FutureBuilder(
      future: _myData,
      builder: (context, Snapshot) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        Icons.arrow_back,
                        size: 30,
                      ),
                    ),
                  ),
                  Text(
                    "Replies",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.close,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
            CommentWidget(
              comment: widget.comment,
              showR: false,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(72, 0, 0, 0),
                child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.comment.replies.length,
                    itemBuilder: (context, index) {
                      Future<List<Comment>> _myCommentDataById =
                          fetchCommentsById(
                              int.parse(widget.comment.replies[index]));
                      return FutureBuilder(
                          future: _myCommentDataById,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: Text(""));
                            } else if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return Center(child: Text(''));
                            }

                            final comments = snapshot.data!;

                            if (snapshot.hasData) {
                              final user = snapshot.data;

                              return CommentWidget(
                                comment: comments[0],
                                showR: false,
                              );
                            } else {
                              // A Widget to show while the value loads
                              return Text("No data found");
                            }
                          });
                    }),
              ),
            ),
            CommentInputField(
              controller: _commentController,
              onSend: _addComment,
              isReply: true,
            )
          ],
        );
      },
    );
  }
}
