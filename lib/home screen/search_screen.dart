import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube/home%20screen/users.dart';

import '../video_player.dart';
import 'base_screen.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> todos = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  /*void initState() {
    super.initState();
    fetchTodos();
  }*/

  String n = "";

  Future<void> search(String query) async {
    try {
      final response2 = await supabase.from('videos').select();
      final response = await supabase
          .from('videos')
          .select().ilike('title', '%$query%')
          .select();

      if (response.isNotEmpty) {
        setState(() {
          todos = List<Map<String, dynamic>>.from(response as List);
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,

              decoration: InputDecoration(
                labelText: 'Search',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    todos.clear();
                    search(_searchController.text);
                  },
                ),
              ),
            ),
            Expanded(
              child: todos.isEmpty
                  ? Center(child: Text("No match found"))
                  : ListView.builder(
                      itemCount: todos.length,
                      itemBuilder: (context, index) {
                        final todo = todos[index];
                        return Card(
                          //elevation: 0,
                          color: Colors.white,
                          margin: EdgeInsets.fromLTRB(0, 0, 0, 60),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: GestureDetector(
                                  onTap: () {

                                    if(liked.contains(todo['videoUrl'].toString()))
                                      isLikedGlobal=true;
                                    else
                                      isLikedGlobal=false;

                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                VideoPlayerScreen(
                                                  videoUrl: todo['videoUrl']
                                                      .toString(),
                                                  title: todo['title'],
                                                  description:
                                                      todo['description'],
                                                  views: todo['views'],
                                                  thumnailUrl:
                                                      todo['thumbnailUrl'],
                                                  ownerID: todo['ownerID'],
                                                  likedBy: todo['likedBy'],
                                                  isLiked: isLikedGlobal,
                                                  id: todo['id'],
                                                  created_at: todo['created_at'],

                                                )));
                                  },
                                  child: Image.network(
                                    todo['thumbnailUrl'],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Container(
                                      width: 330,
                                      child: Text(
                                        todo['title'],
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 0, 8, 0),
                                    child: Icon(Icons.more_vert),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  children: <Widget>[
                                    Text(
                                      '${todo['views'].toString()} views   ',
                                      style: TextStyle(
                                          fontSize: 12.0, color: Colors.grey),
                                    ),
                                    Text(
                                      'Posted 3 months ago',
                                      style: TextStyle(
                                          fontSize: 12.0, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}
