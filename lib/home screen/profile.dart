import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube/home%20screen/home_screen.dart';
import 'package:youtube/home%20screen/users.dart';

import '../main.dart';

String val1 = "";
String val2 = "";
String currUserName="";
String currUserDp="";
List currUserLiked=[];
List currUserFollowers=[];

class ProfilePageNew extends StatefulWidget {
  const ProfilePageNew({super.key});
  @override
  State<ProfilePageNew> createState() => _ProfilePageNewState();
}
Future<List<CurrentUser>>  _myData =fetchCurrentUsers();
Future<List<CurrentUser>> fetchCurrentUsers() async {
  final response = await Supabase.instance.client
      .from('users')
      .select()
      .eq('userID', supabase.auth.currentUser!.id.toString());
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





  @override
  void initState() {
    super.initState();


  }



  File? _image;
  final ImagePicker _picker = ImagePicker();
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });

    if (_image != null) {
      setState(() async {
        await _uploadImage(_image!);
      });
    }
  }

  Future<void> _uploadImage(File image) async {
    final userId = _supabase.auth.currentUser!.id;

    final filePath = 'public/$userId';
    try {
      final response =
          await _supabase.storage.from('avatars').update(filePath, image);

      if (response.isNotEmpty) {
        final imageUrl =
            _supabase.storage.from('avatars').getPublicUrl(filePath);
        await _updateUserProfile(imageUrl);
      } else {
        // Handle error
        print('Upload error: ${response.toString()}');
      }
    } catch (error) {
      final response =
          await _supabase.storage.from('avatars').upload(filePath, image);

      if (response.isNotEmpty) {
        final imageUrl =
            _supabase.storage.from('avatars').getPublicUrl(filePath);
        await _updateUserProfile(imageUrl);
      } else {
        // Handle error
        print('Upload error: ${response.toString()}');
      }
    }
  }

  Future<void> _updateUserProfile(String imageUrl) async {
    final userId = _supabase.auth.currentUser!.id;

    final response = await _supabase.from('users').update({
      'dp': imageUrl,
    }).eq('userID', userId);

    if (response.error != null) {
      // Handle error
      print('Update error: ${response.error!.message}');
    }
    setState(() {
      fetchCurrentUsers();
    });
  }



  @override
  Widget build(BuildContext context) {
    var futureBuilder = FutureBuilder<List<CurrentUser>>(
        future: _myData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No users found.'));
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final Cuser = users[index];
              liked=Cuser.liked;
              currUserName=Cuser.name;
              currUserDp=Cuser.dp;

              return SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: <Widget>[
                          GestureDetector(
                            onTap: () {
                              _pickImage();
                            },
                            child: CircleAvatar(
                              radius: 40.0,
                              backgroundImage: _image == null
                                  ? NetworkImage(Cuser.dp)
                                  : Image.file(_image!).image,
                            ),
                          ),
                          if (Cuser.name.trim() == "")
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "User Name",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          SizedBox(width: 16.0),
                          //if(profile['name']!=" ")
                          if (Cuser.name.trim() != "")
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          0, 0, 10, 0),
                                      child: Text(
                                        Cuser.name,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  Cuser.email == " " ? "" : Cuser.email,
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  Cuser.phone == " " ? "" : Cuser.phone,
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          GestureDetector(
                              onTap: () {
                                setState(() {
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
                                              val1 = "$text1";
                                            },
                                          ),
                                          TextField(
                                            decoration: InputDecoration(
                                              icon: Icon(Icons.phone),
                                              labelText: 'Phone Number',
                                            ),
                                            onChanged: (text2) {
                                              val2 = "$text2";
                                            },
                                          ),
                                        ],
                                      ),
                                      buttons: [
                                        DialogButton(
                                          onPressed: () async {
                                            await supabase
                                                .from("users")
                                                .update({
                                              'name': val1==null?Cuser.name:val1,
                                              'phone': val2==null?Cuser.phone:val2,
                                            }).eq(
                                                    'userID',
                                                    supabase
                                                        .auth.currentUser!.id
                                                        .toString());

                                            setState(() {
                                              _myData =fetchCurrentUsers();
                                              
                                              print("gggggg");
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            "Save",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 20),
                                          ),
                                        )
                                      ]).show();
                                  fetchCurrentUsers();
                                });
                              },
                              child: Icon(Icons.edit))
                        ],
                      ),
                    ),
                    SizedBox(height: 4.0),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          _buildStatColumn('Videos', '10'),
                          _buildStatColumn(
                              'Subscribers', "${Cuser.followers.length}"),
                          _buildStatColumn(
                              'Subscribed', '${Cuser.following.length}'),
                          _buildStatColumn('Views', '50K'),
                        ],
                      ),
                    ),
                    SizedBox(height: 10.0),
                    TextButton(
                      onPressed: () async {
                        await supabase.auth.signOut();
                        setState(() {
                          userIs = false;
                          currF=[];
                          liked=[];
                          dispose();
                          

                        });
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (context) => HomeScreen()));
                      },
                      child: Text(
                        "SignOut",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),


                  ],
                ),
              );
            },
          );
        },
      );
    return new Scaffold(

      body: futureBuilder,
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

  Widget _buildVideoTile(Map<String, String> video) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: Image.asset("assets/logo.png"),
        title: Text(video['title']!),
        onTap: () {
          // Handle video tap, e.g., navigate to video player screen
          print('Tapped video: ${video['title']}');
        },
      ),
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
      liked: json['liked']== null ? [] : json['liked'],
    );
  }
}
