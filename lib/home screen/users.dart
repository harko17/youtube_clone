import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cupertino_icons/cupertino_icons.dart';


import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube/chatService/ChatPage.dart';
import 'package:youtube/home%20screen/profile.dart';
import 'package:youtube/home%20screen/profile_details.dart';
import 'package:youtube/main.dart';
List<dynamic> currF=[];
List<dynamic> liked=[];
Future<List<User>> fetchUsers() async {
  final response = await Supabase.instance.client
      .from('users')
      .select();

  if (response.isEmpty) {
    print('Error fetching users: ${response}');
    return [];
  }

  final List<dynamic> data = response;
  return data.map((json) => User.fromJson(json)).toList();
}




class Users extends StatefulWidget {
  const Users({super.key});

  @override
  State<Users> createState() => _UsersState();
}

class _UsersState extends State<Users> {
  late Future<List<User>> futureUsers;

  @override
  void initState() {
    super.initState();
    futureUsers = fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: FutureBuilder<List<User>>(
        future: futureUsers,
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
              final user = users[index];
              if(supabase.auth.currentUser!=null)
              if(user.userID==supabase.auth.currentUser!.id)
                {
                  currF=user.following;

                }
              return InkWell(
                splashColor: Colors.purple[100],
                onTap: (){
                  print("Tapped");
                  Navigator.of(context).push(MaterialPageRoute(builder: (context)=>ProfileDetails(Ufollowers: user.followers,Ufollowing: user.following)));
                },
                child: ListTile(

                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(user.dp.isNotEmpty ? user.dp : 'https://example.com/default-avatar.png'),
                  ),
                  title: Text(user.name),
                  subtitle: Text('${user.followers.length} Followers'),

                  trailing: Wrap(
                    spacing: 12,
                    children: <Widget>[

                      IconButton(onPressed: (){
                        if(supabase.auth.currentUser!=null)
                          Navigator.of(context).push(MaterialPageRoute(builder: (context)=>ChatPage(userId: supabase.auth.currentUser!.id, receiverId: user.userID)));
                      }, icon: Icon(Icons.message_outlined)),
                      ElevatedButton(

                        onPressed: () async {
                          if(supabase.auth.currentUser!=null)
                          {
                            if(currF.contains(user.userID))
                              {
                                user.followers.remove(supabase.auth.currentUser!.id);
                                await supabase.from("users").update(
                                    {

                                      'followers': user.followers,
                                    }
                                ).eq('userID', user.userID);
                                currF.remove(user.userID);
                                await supabase.from("users").update(
                                    {
                                      'following': currF,

                                    }
                                ).eq('userID', supabase.auth.currentUser!.id);
                              }
                            else
                              {
                                user.followers.add(supabase.auth.currentUser!.id);
                                await supabase.from("users").update(
                                    {

                                      'followers': user.followers,
                                    }
                                ).eq('userID', user.userID);

                                currF.add(user.userID);
                                await supabase.from("users").update(
                                    {
                                      'following': currF,

                                    }
                                ).eq('userID', supabase.auth.currentUser!.id);

                              }
                            print('Follow button pressed for ${user.name}');
                            print('User Following $currF');

                            setState(() {
                              fetchUsers();
                              fetchCurrentUsers();

                            });
                          }
                          else
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content : Text("Please Sign In")));

                        },

                        child: Text(currF.contains(user.userID)?'Following':'Follow'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
class User {
  final String dp;
  final String name;

  final String userID;
  final List followers;
  final List following;
  final List liked;


  User({required this.dp, required this.name,required this.userID,required this.followers,required this.following,required this.liked});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      dp: json['dp'],
      name: json['name'],

      userID: json['userID'],
      followers: json['followers']==null?[]:json['followers'],
      following: json['following']==null?[]:json['following'],
      liked: json['liked']==null?[]:json['liked'],

    );
  }
}

