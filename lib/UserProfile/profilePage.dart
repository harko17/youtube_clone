import 'package:flutter/material.dart';
import 'package:youtube/home%20screen/profile.dart';

import '../home screen/base_screen.dart';
import '../home screen/users.dart';
import '../main.dart';
import '../video_player.dart';

class ProfilePage extends StatefulWidget {
  final String userID;


   ProfilePage({

    required this.userID,

  }) ;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<Map<String, dynamic>> _myVideos = [];
  num currviewsSum=0;
  Future<void> _fetchMyVideos() async {
    final currentUser = widget.userID;
    if (currentUser != null) {
      final response =
      await supabase.from('videos').select().eq('ownerID', widget.userID);

      if (response.isNotEmpty) {
        setState(() {
          _myVideos = List<Map<String, dynamic>>.from(response as List);
          currviewsSum = _myVideos.fold(0, (total, video) => total + (video['views'] ?? 0));

          print(response);
        });
      } else {
        print('Error fetching videos: ${response}');
      }
    }
  }
  void _incrementViews(int videoId,int views) async {

    try {
      // Update the view count for the specific video by incrementing the `views` column by 1
      final response = await supabase
          .from('videos')
          .update({
        'views':  views+1,
      })
          .eq('id', videoId)
          .single();

      if (response != null ) {
        print('Views updated successfully');
      } else {
        print('Error updating views: ${response}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
  @override
  void initState() {
    super.initState();
    _fetchMyVideos();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),

      ),
      body: FutureBuilder<List<CurrentUser>>(
        future: fetchCurrentUsers(widget.userID),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No users found.'));
          }

          final users = snapshot.data!;
          if (users.isEmpty) {
            return Center(child: Text('No user data available.'));
          }

          final Cuser = users[0]; // Assuming there's only one user fetched

          currUserName = Cuser.name;
          currUserDp = Cuser.dp;

          return SingleChildScrollView(

            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(16.0),
                  color: Colors.blueAccent.withOpacity(0.1),
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 40.0,
                        backgroundImage: NetworkImage(Cuser.dp),
                        backgroundColor: Colors.grey[300],
                      ),
                      SizedBox(width: 16.0),
                      if (Cuser.name.trim() != "")
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                Cuser.name,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.0),
                              if (Cuser.email.isNotEmpty)
                                Text(
                                  Cuser.email,
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              if (Cuser.phone.isNotEmpty)
                                Text(
                                  Cuser.phone,
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.grey[700],
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 16.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          _buildStatColumn('Videos', _myVideos.length.toString()),
                          _buildStatColumn('Subscribers', "${Cuser.followers.length}"),
                          _buildStatColumn('Subscribed', '${Cuser.following.length}'),
                          _buildStatColumn('Views', currviewsSum.toString()),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16.0),
                if (_myVideos.isEmpty)
                  Center(
                    child: Text(
                      "No videos",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("Videos",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                        ),
                        Container(
                          height: MediaQuery.of(context).size.height,
                          child: GridView.builder(
                            shrinkWrap: true,
                            gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _myVideos.length,
                            itemBuilder: (context, index) {
                              final video = _myVideos[index];

                              return GestureDetector(

                                onTap: () {
                                  _incrementViews(video['id'],video['views']);

                                  if(liked.contains(video['videoUrl'].toString()))
                                    isLikedGlobal=true;
                                  else
                                    isLikedGlobal=false;
                                  Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => VideoPlayerScreen(
                                        videoUrl: video['videoUrl'].toString(),
                                        title: video['title'],
                                        description: video['description'],
                                        views: video['views'],
                                        thumnailUrl: video['thumbnailUrl'],
                                        ownerID: video['ownerID'],
                                        likedBy: video['likedBy']==null?[]:video['likedBy'],
                                        isLiked: isLikedGlobal,
                                        id: video['id'],
                                        created_at:video['created_at'],
                                        commentId: video['commentId']==null?[]:video['commentId'],
                                      )));
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        video['thumbnailUrl'],
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      video['title'],
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '${video['views']} views',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );

  }

  Widget _buildStatColumn(String label, String count) {
    return Column(
      children: <Widget>[
        Text(
          count,
          style: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4.0),
        Text(
          label,
          style: TextStyle(
            fontSize: 16.0,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
