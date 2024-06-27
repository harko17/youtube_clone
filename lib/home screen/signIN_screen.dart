





import 'dart:async';


import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube/auth/Authentication.dart';
import 'package:youtube/home%20screen/home_screen.dart';

import '../main.dart';


class ProfilePage2 extends StatefulWidget {


  @override
  State<ProfilePage2> createState() => _ProfilePage2State();
}
 bool _redirecting = false;
late  StreamSubscription<AuthState> _authStateSubscription;
class _ProfilePage2State extends State<ProfilePage2> {
  @override
  void initState() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen(
          (data) {
        if (_redirecting) return;
        final session = data.session;
        if (session != null) {
          _redirecting = true;
          setState(() {
            userIs=true;
            _redirecting = false;
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) =>  HomeScreen()));

          });
        }
      },
      onError: (error) {
        if (error is AuthException) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content : Text(error.message)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content : Text("An internal error occured")));
        }
      },
    );
    super.initState();
  }

  @override
  void dispose() {

    _authStateSubscription.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.account_circle,
              size: 100.0,
              color: Colors.grey,
            ),
            SizedBox(height: 20.0),
            Text('You are not signed in',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10.0),
            Text(
              'Sign in to view your profile',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {

                Navigator.of(context).push(MaterialPageRoute(builder: (context)=>AuthPage()));
                print('Sign in button tapped');
              },
              child: Text('Sign In'),
            ),
            SizedBox(height: 10.0),



            ],
        ),
      ),
    );
  }
}