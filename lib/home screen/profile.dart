import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube/home%20screen/home_screen.dart';
import 'package:youtube/home%20screen/signIN_screen.dart';
import 'package:youtube/home%20screen/users.dart';

import '../main.dart';
import '../video_player.dart';
import 'base_screen.dart';

String val1 = "";
String val2 = "";
String currUserName = "";
String currUserDp = "";
List currUserLiked = [];
List currUserFollowers = [];
num viewsSum=0;

class ProfilePageNew extends StatefulWidget {
  const ProfilePageNew({super.key});
  @override
  State<ProfilePageNew> createState() => _ProfilePageNewState();
}

Future<List<CurrentUser>> _myData = fetchCurrentUsers(supabase.auth.currentUser!.id.toString());

Future<List<CurrentUser>> fetchCurrentUsers(String userID) async {

  final response = await Supabase.instance.client
      .from('users')
      .select()
      .eq('userID', userID);
  ;

  if (response.isEmpty) {
    print('Error fetching users: ${response}');
    return [];
  }

  final List<dynamic> data = response;
  return data.map((json) => CurrentUser.fromJson(json)).toList();
}

class _ProfilePageNewState extends State<ProfilePageNew> {
  final SupabaseClient supabase = Supabase.instance.client;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _myVideos = [];

  @override
  void initState() {
    super.initState();
    _fetchMyVideos();
  }

  Future<void> _fetchMyVideos() async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser != null) {
      final response =
          await supabase.from('videos').select().eq('ownerID', currentUser.id);

      if (response.isNotEmpty) {
        setState(() {
          _myVideos = List<Map<String, dynamic>>.from(response as List);
          viewsSum = _myVideos.fold(0, (total, video) => total + (video['views'] ?? 0));

          print(response);
        });
      } else {
        print('Error fetching videos: ${response}');
      }
    }
  }

  Future<List<CurrentUser>> fetchCurrentUsers() async {

    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null)
      return []; // Handle case where user is not signed in

    final response =
        await supabase.from('users').select().eq('userID', currentUserId);

    if (response.isEmpty) {
      print('Error fetching users: $response');
      return [];
    }

    final List<dynamic> data = response;
    return data.map((json) => CurrentUser.fromJson(json)).toList();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });

    if (_image != null) {
      await _uploadImage(_image!);
    }
  }

  Future<void> _uploadImage(File image) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return; // Ensure user ID is available

    final filePath = 'public/$userId';
    try {
      final response =
          await supabase.storage.from('avatars').update(filePath, image);

      if (response.isNotEmpty) {
        final imageUrl =
            supabase.storage.from('avatars').getPublicUrl(filePath);
        await _updateUserProfile(imageUrl);
      } else {
        print('Upload error: ${response.toString()}');
      }
    } catch (error) {
      final response =
          await supabase.storage.from('avatars').upload(filePath, image);

      if (response.isNotEmpty) {
        final imageUrl =
            supabase.storage.from('avatars').getPublicUrl(filePath);
        await _updateUserProfile(imageUrl);
      } else {
        print('Upload error: ${response.toString()}');
      }
    }
  }

  void _showDeleteConfirmation(int videoId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this video?'),
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
                _deleteVideo(videoId);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
  void _deleteVideo(int messageId) async {
    final response = await Supabase.instance.client
        .from('videos')
        .delete()
        .match({'id': messageId}).whenComplete(() => _fetchMyVideos());

    if (response.error != null) {
      print('Error deleting message: ${response.error!.message}');
    } else {
      setState(() {
        _myVideos.removeWhere((message) => message['id'] == messageId);

        listenForNewMessages();
      });
    }
  }
  void listenForNewMessages() {
    final supabase = Supabase.instance.client;

    final stream = supabase
        .from('videos') // Specify the table to listen to
        .stream(primaryKey: ['id']) // Provide the primary key column(s)
        .eq('ownerID', supabase.auth.currentUser!.id) // Optional: filter by receiver_id
        .listen((List<Map<String, dynamic>> data) {
      setState(() {
        _myVideos.addAll(data);
        _fetchMyVideos();// Add the new messages to your list
      });
    });
  }
  Future<void> _updateUserProfile(String imageUrl) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return; // Ensure user ID is available

    final response = await supabase.from('users').update({
      'dp': imageUrl,
    }).eq('userID', userId);

    if (response.error != null) {
      print('Update error: ${response.error!.message}');
    }
    setState(() {
      // Force UI to refresh by re-fetching user data
    });
  }

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();
      setState(() {
        currUserName = "";
        currUserDp = "";
        currUserLiked = [];
        currUserFollowers = [];
        _image = null;
        userIs = false;
        currF = [];
        liked = [];
        viewsSum=0;
      });
      // Navigate to the HomeScreen after signing out
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      print('Sign out error: $e');
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<CurrentUser>>(
        future: fetchCurrentUsers(),
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
                  child: Row(
                    children: <Widget>[
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 40.0,
                          backgroundImage: _image == null
                              ? NetworkImage(Cuser.dp)
                              : Image.file(_image!).image,
                        ),
                      ),
                      SizedBox(width: 16.0),
                      if (Cuser.name.trim() != "")
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              Cuser.name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              Cuser.email.isEmpty ? "" : Cuser.email,
                              style: TextStyle(
                                fontSize: 16.0,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              Cuser.phone.isEmpty ? "" : Cuser.phone,
                              style: TextStyle(
                                fontSize: 16.0,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),

                      GestureDetector(
                        onTap: () {
                          Alert(
                            context: context,
                            title: "Profile",
                            content: Column(
                              children: <Widget>[
                                TextField(
                                  decoration: InputDecoration(
                                    icon: Icon(Icons.account_circle),
                                    labelText: 'Username',
                                  ),
                                  onChanged: (text1) {
                                    val1 = text1;
                                  },
                                ),
                                TextField(
                                  decoration: InputDecoration(
                                    icon: Icon(Icons.phone),
                                    labelText: 'Phone Number',
                                  ),
                                  keyboardType: TextInputType.number, // Numeric keyboard
                                  maxLength: 10, // Limit to 10 characters
                                  onChanged: (text2) {
                                    val2 = text2;
                                  },
                                ),
                              ],
                            ),
                            buttons: [
                              DialogButton(
                                onPressed: () async {
                                  // Validate username
                                  if (val1.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Username cannot be empty")),
                                    );
                                    return;
                                  }

                                  // Validate phone number
                                  if (val2.length != 10 || !RegExp(r'^\d{10}$').hasMatch(val2)) {

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Phone number must be 10 digits")),
                                    );
                                    return;
                                  }

                                  // Proceed with updating the user's profile
                                  await supabase.from("users").update({
                                    'name': val1.isEmpty ? Cuser.name : val1,
                                    'phone': val2.isEmpty ? Cuser.phone : val2,
                                  }).eq('userID', supabase.auth.currentUser!.id);

                                  setState(() {
                                    // Refresh the data
                                  });
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  "Save",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              )
                            ],
                          ).show();

                        },
                        child: Icon(Icons.edit),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4.0),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      _buildStatColumn('Videos', _myVideos.length.toString()),
                      _buildStatColumn(
                          'Subscribers', "${Cuser.followers.length}"),
                      _buildStatColumn(
                          'Subscribed', '${Cuser.following.length}'),
                      _buildStatColumn('Views', viewsSum.toString()),
                    ],
                  ),
                ),
                SizedBox(height: 10.0),
                TextButton(
                  onPressed: _signOut,
                  child: Text(
                    "SignOut",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                _myVideos.isEmpty
                    ? Center(child: Text("No videos found."))
                    : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("My Videos",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
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
                                  onLongPress: (){
                                    _showDeleteConfirmation(video['id']);
                                  },
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

class CurrentUser {
  final String dp;
  final String name;

  final String userID;
  final List followers;
  final List following;
  final String email;
  final String phone;
  final List liked;

  CurrentUser(
      {required this.dp,
      required this.name,
      required this.userID,
      required this.followers,
      required this.following,
      required this.email,
      required this.phone,
      required this.liked});

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      dp: json['dp'],
      name: json['name'],
      userID: json['userID'],
      followers: json['followers'] == null ? [] : json['followers'],
      following: json['following'] == null ? [] : json['following'],
      email: json['email'],
      phone: json['phone'],
      liked: json['liked'] == null ? [] : json['liked'],
    );
  }
}
