import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube/UserProfile/profilePage.dart';
import 'package:youtube/home%20screen/profile.dart';
import 'package:youtube/home%20screen/profile_details.dart';

import '../chatService/ChatPage.dart';
import '../main.dart';

List<dynamic> currF = [];
List<dynamic> liked = [];

Future<List<User>> fetchUsers() async {
  final response = await Supabase.instance.client.from('users').select();
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
  List<Map<String, dynamic>> usersGot = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    futureUsers = fetchUsers();
    fetchCurrentUserFollowing();
  }

  Future<void> fetchCurrentUserFollowing() async {
    if (Supabase.instance.client.auth.currentUser != null) {
      final response = await Supabase.instance.client
          .from('users')
          .select('following')
          .eq('userID', Supabase.instance.client.auth.currentUser!.id)
          .single();

      if (response != null && response['following'] != null) {
        setState(() {
          currF = List<dynamic>.from(response['following']);
        });
      } else {
        print('Error fetching following list: $response');
      }
    }
  }

  Future<void> searchUser(String query) async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .ilike('name', '%$query%');

      if (response.isNotEmpty) {
        setState(() {
          usersGot = List<Map<String, dynamic>>.from(response);
          errorMessage = null; // Clear any previous error message
        });
      } else {
        setState(() {
          usersGot = [];
          errorMessage = 'No match found';
        });
      }
    } catch (error) {
      setState(() {
        usersGot = [];
        errorMessage = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search',
                hintText: 'Enter user name',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (query) {
                searchUser(query);
              },
            ),
          ),
          Expanded(
            child: (usersGot.isEmpty && errorMessage == null)
                ? FutureBuilder<List<User>>(
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
                          if (user.userID == supabase.auth.currentUser?.id) {
                            currF = user.following;
                          }
                          if (user.userID ==
                              supabase.auth.currentUser?.id.toString())
                            return SizedBox(); // Adjusted from Spacer to SizedBox

                          return InkWell(
                            splashColor: Colors.purple[100],
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => ProfileDetails(
                                      Ufollowers: user.followers,
                                      Ufollowing: user.following)));
                            },
                            child: ListTile(
                              leading: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => ProfilePage(
                                                userID: user.userID,
                                              )));
                                },
                                child: CircleAvatar(
                                  backgroundImage: NetworkImage(user
                                          .dp.isNotEmpty
                                      ? user.dp
                                      : 'https://example.com/default-avatar.png'),
                                ),
                              ),
                              title: Text(
                                  user.name == ' ' ? "New User" : user.name),
                              subtitle:
                                  Text('${user.followers.length} Followers'),
                              trailing: Wrap(
                                spacing: 12,
                                children: <Widget>[
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (supabase.auth.currentUser != null) {
                                        if (currF.contains(user.userID)) {
                                          user.followers.remove(
                                              supabase.auth.currentUser!.id);
                                          await supabase.from("users").update({
                                            'followers': user.followers,
                                          }).eq('userID', user.userID);
                                          currF.remove(user.userID);
                                          await supabase.from("users").update({
                                            'following': currF,
                                          }).eq('userID',
                                              supabase.auth.currentUser!.id);
                                        } else {
                                          user.followers.add(
                                              supabase.auth.currentUser!.id);
                                          await supabase.from("users").update({
                                            'followers': user.followers,
                                          }).eq('userID', user.userID);
                                          currF.add(user.userID);
                                          await supabase.from("users").update({
                                            'following': currF,
                                          }).eq('userID',
                                              supabase.auth.currentUser!.id);
                                        }
                                        setState(() {
                                          fetchUsers();
                                          fetchCurrentUserFollowing();
                                        });
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content:
                                                    Text("Please Sign In")));
                                      }
                                    },
                                    child: Text(currF.contains(user.userID)
                                        ? 'Following'
                                        : 'Follow'),
                                  ),
                                  IconButton(
                                      onPressed: () async {
                                        if (supabase.auth.currentUser != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => ChatPage(
                                                      currentUserID: supabase
                                                          .auth.currentUser!.id,
                                                      otherUserID: user.userID,
                                                      otherUserDp: user.dp,
                                                      otherUserName: user.name,
                                                      currentUserName:
                                                          currUserName,
                                                      currentUserDp: currUserDp,
                                                    )),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content:
                                                      Text("Please Sign In")));
                                        }
                                      },
                                      icon: Icon(Icons.message_outlined)),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  )
                : usersGot.isNotEmpty
                    ? ListView.builder(
                        itemCount: usersGot.length,
                        itemBuilder: (context, index) {
                          final user = usersGot[index];
                          if (user['userID'] == supabase.auth.currentUser?.id) {
                            currF = user['following']==null?[]:user['following'];
                          }
                          if (user['userID'] ==
                              supabase.auth.currentUser?.id.toString())
                            return SizedBox(); // Adjusted from Spacer to SizedBox
                          return InkWell(
                            splashColor: Colors.purple[100],
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => ProfileDetails(
                                      Ufollowers: user['followers']==null?[]:user['followers'],
                                      Ufollowing: user['following']==null?[]:user['following'])));
                            },
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(user['dp']
                                        .isNotEmpty
                                    ? user['dp']
                                    : 'https://example.com/default-avatar.png'),
                              ),
                              title: Text(user['name'] == ' '
                                  ? "New User"
                                  : user['name']),
                              subtitle: Text(
                                  '${(user['followers']==null?[]:user['followers'] as List).length} Followers'),
                              trailing: Wrap(
                                spacing: 12,
                                children: <Widget>[
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (supabase.auth.currentUser != null) {
                                        if (currF.contains(user['userID'])) {
                                          (user['followers'] as List).remove(
                                              supabase.auth.currentUser!.id);
                                          await supabase.from("users").update({
                                            'followers': user['followers'],
                                          }).eq('userID', user['userID']);
                                          currF.remove(user['userID']);
                                          await supabase.from("users").update({
                                            'following': currF,
                                          }).eq('userID',
                                              supabase.auth.currentUser!.id);
                                        } else {
                                          (user['followers'] as List).add(
                                              supabase.auth.currentUser!.id);
                                          await supabase.from("users").update({
                                            'followers': user['followers'],
                                          }).eq('userID', user['userID']);
                                          currF.add(user['userID']);
                                          await supabase.from("users").update({
                                            'following': currF,
                                          }).eq('userID',
                                              supabase.auth.currentUser!.id);
                                        }
                                        setState(() {
                                          fetchUsers();
                                          fetchCurrentUserFollowing();
                                        });
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content:
                                                    Text("Please Sign In")));
                                      }
                                    },
                                    child: Text(currF.contains(user['userID'])
                                        ? 'Following'
                                        : 'Follow'),
                                  ),
                                  IconButton(
                                      onPressed: () async {
                                        if (supabase.auth.currentUser != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => ChatPage(
                                                      currentUserID: supabase
                                                          .auth.currentUser!.id,
                                                      otherUserID:
                                                          user['userID'],
                                                      otherUserDp: user['dp'],
                                                      otherUserName:
                                                          user['name'],
                                                      currentUserName:
                                                          currUserName,
                                                      currentUserDp: currUserDp,
                                                    )),
                                          );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content:
                                                      Text("Please Sign In")));
                                        }
                                      },
                                      icon: Icon(Icons.message_outlined)),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : Center(child: Text(errorMessage ?? '')),
          ),
        ],
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
  final int id;

  User({
    required this.dp,
    required this.name,
    required this.userID,
    required this.followers,
    required this.following,
    required this.liked,
    required this.id,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      dp: json['dp'] ?? '',
      name: json['name'] ?? '',
      userID: json['userID'] ?? '',
      followers: json['followers'] == null ? [] : json['followers'],
      following: json['following'] == null ? [] : json['following'],
      liked: json['liked'] == null ? [] : json['liked'],
      id: json['id'] ?? 0,
    );
  }
}
