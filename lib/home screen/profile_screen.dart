import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube/home%20screen/home_screen.dart';

String val1="";
String val2="";
class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final List<Map<String, String>> videos = [
    {
      'title': 'My First Video',
      'thumbnailUrl': 'https://oejwazbjlcsayyzpknmg.supabase.co/storage/v1/object/public/thumbnail/SUPA__1_.png',
    },
    {
      'title': 'Another Interesting Video',
      'thumbnailUrl': 'https://oejwazbjlcsayyzpknmg.supabase.co/storage/v1/object/public/thumbnail/SUPA__2_.png',
    },
    {
      'title': 'Flutter Tutorial',
      'thumbnailUrl': 'https://oejwazbjlcsayyzpknmg.supabase.co/storage/v1/object/public/thumbnail/SUPA__3_.png',
    },
  ];

  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> profiles = [];

  bool isLoading = true;
  String? errorMessage;
  @override
  void initState() {
    super.initState();
    fetchProfiles();
  }
  String n="";


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
    try
    {
      final response = await _supabase.storage.from('avatars').update(filePath, image);

      if (response.isNotEmpty) {
        final imageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
        await _updateUserProfile(imageUrl);
      } else {
        // Handle error
        print('Upload error: ${response.toString()}');
      }

    }
    catch(error)
    {
      final response = await _supabase.storage.from('avatars').upload(filePath, image);

      if (response.isNotEmpty) {
        final imageUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
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
      fetchProfiles();
    });
  }
  Future<void> fetchProfiles() async {
    try {
      final response = await supabase
          .from('users')
          .select().eq('userID',supabase.auth.currentUser!.id.toString() );

      if (response.isNotEmpty) {
        setState(() {
          profiles = List<Map<String, dynamic>>.from(response as List);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = response.toString();
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(


      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _buildProfileHeader(),
            _buildStats(),
            _buildVideosList(),
            SizedBox(height: 4.0),

            SizedBox(height: 10.0),
            TextButton(
              onPressed: () async {
                await supabase.auth.signOut();
                setState(() {
                  userIs = false;

                  dispose();
                });
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => HomeScreen()));
              },
              child: Text("SignOut",style: TextStyle(fontSize: 16),),
            ),


          ],
        ),
      ),
    );
  }



Widget _buildProfileHeader() {

  final profile=profiles[0];
  String name=profile['name'];
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Row(
        children: <Widget>[
          GestureDetector(
            onTap: (){
              _pickImage();
            },
            child: CircleAvatar(
              radius: 40.0,
              backgroundImage:  _image == null?NetworkImage(profile['dp'].toString()):Image.file(_image!).image,
            ),
          ),
          if(name.trim()=="")
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "User Name",
              style: TextStyle(
                fontSize:20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 16.0),
          //if(profile['name']!=" ")
          if(name.trim()!="")
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(

                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                    child: Text(
                      profile['name'],
                      style: TextStyle(
                        fontSize:20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),


                ],
              ),
              Text(
                profile['email']==" "?"":profile['email'],
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey,
                ),
              ),
              Text(
                profile['phone']==" "?"":profile['phone'],
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          GestureDetector(

              onTap: ()  {


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
                          onPressed: () async
                          {
                            await supabase.from("users").update(
                                {
                                  'name': val1,

                                  'phone': val2,

                                }
                            ).eq('userID', supabase.auth.currentUser!.id.toString());
                            setState(() {
                              fetchProfiles();
                            });
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Save",
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        )
                      ]).show(
                  );
                  fetchProfiles();

                });
              },
              child: Icon(Icons.edit))
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _buildStatColumn('Videos', '10'),
          _buildStatColumn('Subscribers', '1.2K'),
          _buildStatColumn('Views', '50K'),
        ],
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

  Widget _buildVideosList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return _buildVideoTile(videos[index]);
      },
    );
  }

  Widget _buildVideoTile(Map<String, String> video) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: Image.asset(

            "assets/logo.png")
      ,
        title: Text(video['title']!),
        onTap: () {
          // Handle video tap, e.g., navigate to video player screen
          print('Tapped video: ${video['title']}');
        },
      ),
    );
  }
}
