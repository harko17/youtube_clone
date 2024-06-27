import 'package:flutter/material.dart';
import 'package:youtube/home%20screen/base_screen.dart';

import 'package:youtube/home%20screen/notification_screen.dart';
import 'package:youtube/home%20screen/profile_screen.dart';
import 'package:youtube/home%20screen/signIN_screen.dart';
import 'package:youtube/home%20screen/search_screen.dart';





bool userIs=false;
class HomeScreen extends StatefulWidget {


  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  PageController _pageController = PageController();

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
    SearchPage(),
    NotificationsPage(),
    userIs==true?ProfilePage():ProfilePage2(),
  ];


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: appbar(),
      body: IndexedStack(
        index: _currentIndex,
        children: _children,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: onTabTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
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
      ),
    );
  }
}
 appbar()
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
          // handle the press
        },
      ),

      IconButton(
        icon: const Icon(Icons.search),
        tooltip: 'Search',
        onPressed: () {
          // handle the press
        },
      ),
    ],
    title: Text('YouTube',style: TextStyle(fontWeight: FontWeight.bold),),
  );
}