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
  void initState() {
    super.initState();
  }

  Future<void> search(String query) async {
    try {
      final response = await supabase
          .from('videos')
          .select()
          .ilike('title', '%$query%')
          .select();

      if (response.isNotEmpty) {
        setState(() {
          todos = List<Map<String, dynamic>>.from(response as List);
          isLoading = false;
          errorMessage = null; // Clear any previous error message
        });
      } else {
        setState(() {
          todos = [];
          errorMessage = "No match found";
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        todos = [];
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  void _incrementViews(int videoId, int views) async {
    try {
      final response = await supabase
          .from('videos')
          .update({
        'views': views + 1,
      })
          .eq('id', videoId)
          .single();

      if (response != null) {
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
      appBar: AppBar(
        elevation: 20,
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 5, 0),
          child: Image.asset("assets/logo.png"),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.screen_share),
            tooltip: 'Screen Share',
            onPressed: () {
              // handle the press
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            tooltip: 'Notifications',
            onPressed: () {
              // handle the press
            },
          ),
        ],
        title: Text(
          'GRIND',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: "Play"),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Search',
                  hintText: 'Enter video title',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onChanged: (query) {
                  search(query);
                },
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : errorMessage != null
                  ? Center(child: Text(errorMessage!))
                  : todos.isEmpty
                  ? Center(child: Text("No match found"))
                  : ListView.builder(
                itemCount: todos.length,
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  bool isLikedGlobal = false;

                  return Card(
                    color: Colors.white,
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 60),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: GestureDetector(
                            onTap: () {
                              _incrementViews(todo['id'], todo['views']);
                              if (liked.contains(todo['videoUrl'].toString()))
                                isLikedGlobal = true;
                              else
                                isLikedGlobal = false;

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
                                            commentId: todo['commentId'] == null
                                                ? []
                                                : todo['commentId'],
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
