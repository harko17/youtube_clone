import 'package:flutter/material.dart';
import 'package:youtube/home%20screen/base_screen.dart';

import 'package:youtube/home%20screen/notification_screen.dart';
import 'package:youtube/home%20screen/profile.dart';
import 'package:youtube/home%20screen/signIN_screen.dart';
import 'package:youtube/home%20screen/search_screen.dart';
import 'package:youtube/home%20screen/users.dart';
import 'package:youtube/main.dart';
import 'package:youtube/toUpload/UploadVideo.dart';





bool userIs=false;
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  PageController _pageController = PageController();
  Widget currentPage = Database();
  final PageStorageBucket bucket = PageStorageBucket();

  @override
  void initState() {
    _currentIndex = 0;
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;

    });
    _pageController.animateToPage(index,
        duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  final List<Widget> _children = [
    Database(),
    Users(),
    VideoUploadScreen(),
    NotificationsPage(),
    userIs==true?ProfilePageNew():ProfilePage2(),
  ];


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: appbar(context),
      body:
      PageStorage(bucket: bucket, child: currentPage),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,

        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (int index) => _showPage(index),
      ),
    );
  }
  void _showPage(int index) {
    setState(() {
      switch (index) {
        case 0:
          currentPage = Database();
          _currentIndex = 0;
          break;
        case 1:
          currentPage = Users();
          _currentIndex = 1;
          break;
        case 2:
          if(supabase.auth.currentUser==null)
            {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content : Text("Please Sign In")));
            }
          else
            {
              currentPage = VideoUploadScreen();
              _currentIndex = 2;
              break;
            }


        case 3:
          currentPage = NotificationsPage();
          _currentIndex = 3;
          break;
        case 4:
          currentPage = userIs==true?ProfilePageNew():ProfilePage2();
          _currentIndex = 4;
          break;
      }
    });
  }
}
 appbar(BuildContext context)
{
  return  AppBar(
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

        },
      ),

      IconButton(
        icon: const Icon(Icons.search),
        tooltip: 'Search',
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context)=>SearchPage()));
        },
      ),
    ],
    title: Text('GRIND',style: TextStyle(fontWeight: FontWeight.bold,fontFamily: "Play",),),
  );
}