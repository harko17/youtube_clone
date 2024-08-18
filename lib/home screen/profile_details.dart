import 'package:cupertino_icons/cupertino_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube/home%20screen/profile.dart';
import 'package:youtube/home%20screen/users.dart';

import '../main.dart';
import 'home_screen.dart';

bool F1 = true;
List<dynamic> strlist =[];
class ProfileDetails extends StatefulWidget {

  final List Ufollowers;
  final List Ufollowing;
  ProfileDetails({required this.Ufollowers, required this.Ufollowing});

  @override
  _ProfileDetailsState createState() => _ProfileDetailsState();
}
Future<List<CurrentUser>>  _myData =fetchCurrentUsersData("");

Future<List<CurrentUser>> fetchCurrentUsersData(String userID) async {
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

class _ProfileDetailsState extends State<ProfileDetails> {
  late Future<List<CurrentUser>> futureUsers;

  @override
  void initState() {
    super.initState();


  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appbar(context),
      body: SingleChildScrollView(
        child: Container(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                        onPressed: () {
                          print(widget.Ufollowers);
                          setState(() {
                            F1 = true;
                          });
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: F1 ? Colors.black12 : null,
                        ),
                        child: Text("Followers")),
                    TextButton(
                        onPressed: () {
                          print(widget.Ufollowing);
                          setState(() {
                            F1 = false;
                          });
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: F1 ? null : Colors.black12,
                        ),
                        child: Text("Following")),
                  ],
                ),
              ),

              if (F1)
                Container(
                  child: (widget.Ufollowers.length != 0)
                      ? ListView.builder(
                          shrinkWrap: true,
                          itemCount: widget.Ufollowers.length,
                          itemBuilder: (context, index) {
                            Future<List<CurrentUser>>  _myData =fetchCurrentUsersData("${widget.Ufollowers[index].toString()}");
                            return FutureBuilder(
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
                                  final Cuser = users[0];

                                  if (snapshot.hasData) {
                                    final user = snapshot.data;
                                    List ll = Cuser.followers;
                                    int n = ll.length;
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage:
                                            NetworkImage(Cuser.dp),
                                      ),
                                      title: Text(Cuser.name),
                                      subtitle: Text('${n} Followers'),
                                      trailing: ElevatedButton(
                                        onPressed: () {
                                          if(supabase.auth.currentUser==null)
                                            {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content : Text("Please Sign In")));

                                            }
                                          else
                                            {

                                            }
                                        },
                                        child: Text(currF.contains(Cuser.userID)?'Following':'Follow'),
                                      ),
                                    );
                                  } else {
                                    // A Widget to show while the value loads
                                    return Text("No data found");
                                  }
                                });
                          })
                      : Center(child: Text("No data found")),
                ),
              if (!F1)
                Container(
                  child: (widget.Ufollowing.length != 0)
                      ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: widget.Ufollowing.length,
                      itemBuilder: (context, index) {
                        Future<List<CurrentUser>>  _myData =fetchCurrentUsersData("${widget.Ufollowing[index].toString()}");
                        return FutureBuilder(
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
                              final Cuser = users[0];

                              if (snapshot.hasData) {
                                final user = snapshot.data;
                                List ll = Cuser.followers;
                                int n = ll.length;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage:
                                    NetworkImage(Cuser.dp),
                                  ),
                                  title: Text(Cuser.name),
                                  subtitle: Text('${n} Followers'),
                                  trailing: ElevatedButton(
                                    onPressed: () {},
                                    child: Text('Follow'),
                                  ),
                                );
                              } else {
                                // A Widget to show while the value loads
                                return Text("No data found");
                              }
                            });
                      })
                      : Center(child: Text("No data found")),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> UserName(String userID) async {
    List<Map<String, dynamic>> UserDetailsAll = [];

    bool isLoading = true;
    String? errorMessage;
    try {
      final response =
          await supabase.from('users').select().eq('userID', '$userID');

      if (response.isNotEmpty) {
        setState(() {
          UserDetailsAll = List<Map<String, dynamic>>.from(response as List);

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

    return UserDetailsAll;
  }
}
