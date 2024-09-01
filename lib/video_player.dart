import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube/features/comments.dart';
import 'package:youtube/home%20screen/base_screen.dart';
import 'package:youtube/home%20screen/home_screen.dart';
import 'package:youtube/home%20screen/profile.dart';
import 'package:youtube/home%20screen/users.dart';
import 'package:youtube/main.dart';

import 'chatService/ChatPage.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;
  final String description;
  final int views;
  final String thumnailUrl;
  final String ownerID;
  final List likedBy;
  final bool isLiked;
  final int id;
  final String created_at;
  final List commentId;

  VideoPlayerScreen({
    required this.videoUrl,
    required this.title,
    required this.description,
    required this.views,
    required this.thumnailUrl,
    required this.ownerID,
    required this.likedBy,
    required this.isLiked,
    required this.id,
    required this.created_at,
    required this.commentId,
  });

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

bool _commentTap = false;


class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {

    super.initState();
    _videoPlayerController = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController,
            autoPlay: true,
            looping: true,
          );
        });
      });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  int _height = 100;
  Color _iconColor = isLikedGlobal ? Colors.blue : Colors.black54;

  void _openComment(){
    showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0.0)),
      ),
      context: (context), builder: (context) => CommentSectionScreen(id: widget.id,commentId:widget.commentId==null?[]:widget.commentId),);
  }



  Future<List<CurrentUser>> fetchCurrentOwner() async {
    final response = await Supabase.instance.client
        .from('users')
        .select().eq('userID', widget.ownerID);

    if (response.isEmpty) {
      print('Error fetching users: ${response}');
      return [];
    }

    final List<dynamic> data = response;
    return data.map((json) => CurrentUser.fromJson(json)).toList();
  }
  @override
  Widget build(BuildContext context) {
    Future<List<CurrentUser>>  _myOwnerData =fetchCurrentOwner();

    return Scaffold(
      appBar: appbar(context),
      body: FutureBuilder(
        future: _getUdata,
        builder: (context, snapshot) {
          if(currUserLiked.contains(widget.videoUrl))
            _iconColor=Colors.blue;
          else
            _iconColor=Colors.black54;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _chewieController != null &&
                        _chewieController!
                            .videoPlayerController.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoPlayerController.value.aspectRatio,
                        child: Chewie(controller: _chewieController!),
                      )
                    : Column(
                        children: [
                          Center(
                            child: Image.network(
                              widget.thumnailUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                          LinearProgressIndicator(),
                        ],
                      ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('${widget.views} views'),
                ),
                FutureBuilder(future: _myOwnerData, builder: (context,snapshot){
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No users found.'));
                  }

                  final owners = snapshot.data!;
                  final owner=owners[0];
                  return ListTile(

                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(owner.dp),
                    ),
                    title: Text(owner.name==currUserName?owner.name+" (Me)":owner.name),
                    subtitle: Text('${owner.followers.length} Followers'),

                    trailing: Wrap(
                      spacing: 12,
                      children: <Widget>[
                        if(owner.name!=currUserName)
                        IconButton(onPressed: (){
                          //if(supabase.auth.currentUser!=null)
                            //Navigator.of(context).push(MaterialPageRoute(builder: (context)=>ChatPage(userId: supabase.auth.currentUser!.id, receiverId: owner.userID)));
                        }, icon: Icon(Icons.message_outlined)),
                        if(owner.name!=currUserName)
                        ElevatedButton(

                          onPressed: () async {
                            if(supabase.auth.currentUser!=null)
                            {
                              if(currF.contains(owner.userID))
                              {
                                owner.followers.remove(supabase.auth.currentUser!.id);
                                await supabase.from("users").update(
                                    {

                                      'followers': owner.followers,
                                    }
                                ).eq('userID', owner.userID);
                                currF.remove(owner.userID);
                                await supabase.from("users").update(
                                    {
                                      'following': currF,

                                    }
                                ).eq('userID', supabase.auth.currentUser!.id);
                              }
                              else
                              {
                                owner.followers.add(supabase.auth.currentUser!.id);
                                await supabase.from("users").update(
                                    {

                                      'followers': owner.followers,
                                    }
                                ).eq('userID', owner.userID);

                                currF.add(owner.userID);
                                await supabase.from("users").update(
                                    {
                                      'following': currF,

                                    }
                                ).eq('userID', supabase.auth.currentUser!.id);

                              }
                              print('User Following $currF');

                              setState(() {
                                fetchUsers();
                                fetchCurrentUsers(supabase.auth.currentUser!.id.toString());

                              });
                            }
                            else
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content : Text("Please Sign In")));

                          },

                          child: Text(currF.contains(owner.userID)?'Following':'Follow'),
                        ),
                      ],
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(widget.description),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.thumb_up,
                            color: _iconColor),
                        onPressed: () async {
                          if (supabase.auth.currentUser != null) {
                            if (!currUserLiked.contains(widget.videoUrl)) {
                              setState(() {
                                _iconColor = Colors.blue;
                              });
                              List likedd = widget.likedBy;
                              likedd.add(supabase.auth.currentUser!.id);

                              print(likedd);

                              await supabase.from("videos").update({
                                'likedBy': likedd,
                              }).eq('videoUrl', widget.videoUrl);

                              likedd.clear();
                              List likeddd = liked;
                              likeddd.add(widget.videoUrl);
                              print(likeddd);

                              await supabase.from("users").update({
                                'liked': likeddd,
                              }).eq('userID', supabase.auth.currentUser!.id);
                              likeddd = [];
                            } else {
                              setState(() {
                                _iconColor = Colors.black54;
                              });
                              List likedd = widget.likedBy;
                              likedd.remove(supabase.auth.currentUser!.id);
                              print(likedd);

                              await supabase.from("videos").update({
                                'likedBy': likedd,
                              }).eq('videoUrl', widget.videoUrl);

                              likedd = [];
                              List likeddd = liked;
                              likeddd.remove(widget.videoUrl);
                              print(likeddd);

                              await supabase.from("users").update({
                                'liked': likeddd,
                              }).eq('userID', supabase.auth.currentUser!.id);
                              likeddd = [];
                            }
                          } else
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Please Sign In")));
                          setState(() {
                            _getUdata=_getUserData();
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.thumb_down),
                        onPressed: () {
                          print(liked);
                          print(currUserName);
                          print(currUserDp);
                          print("aaaaa $currUserLiked");

                          // Handle dislike
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.share),
                        onPressed: () {
                          Share.share(
                              'Check out this amazing video: ${widget.videoUrl}');
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _height = 200;
                        _commentTap = true;
                      });
                    },
                    child: Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _height = 400;
                        _commentTap = false;
                      });
                    },
                    child: GestureDetector(
                      onTap: _openComment,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black,
                          ),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        width: double.infinity,

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 18,top: 10),
                              child: Text("Comments ${widget.commentId.length}",style: TextStyle(fontSize: 18),),
                            ),
                            SizedBox(),
                            ListTile(
                              leading: CircleAvatar(
                                backgroundImage:
                                NetworkImage(currUserDp),
                              ),
                              trailing: Icon(Icons.send),
                              title: TextField(

                                decoration: InputDecoration(
                                  hintText: 'Add a public comment...',
                                  enabled: false,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),

                            ),

                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Add comment section here
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Related Videos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Add related videos section here
              ],
            ),
          );
        },
      ),
    );
  }
}

Future<void> _getUdata=_getUserData();

Future<void> _getUserData() async {
  final response = await Supabase.instance.client
      .from('users')
      .select()
      .eq('userID', supabase.auth.currentUser!.id);
  ;
  currUserName = response[0]['name'];
  currUserDp = response[0]['dp'];
  currUserLiked = response[0]['liked'];
  currUserFollowers=response[0]['followers'];

}