import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube/home%20screen/home_screen.dart';

import '../main.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

bool _redirecting = false;
late StreamSubscription<AuthState> _authStateSubscription;

class _AuthPageState extends State<AuthPage> {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true; // To control password visibility
  String _message = '';

  Future<void> _signUp() async {
    try {
      final response = await _supabaseClient.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (response == null) {
        setState(() {
          _message = response.toString();
        });
      } else {
        setState(() {
          _message = 'Check your email for confirmation';
        });
      }

      await supabase.from("users").insert([
        {
          'dp': ' ',
          'name': 'UserName',
          'phone': ' ',
        }
      ]);
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("User already exists")));
    }
  }

  Future<void> _signIn() async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (response == null) {
        setState(() {
          _message = response.toString();
        });
      } else {
        setState(() {
          userIs = true;
          _message = 'Signed in successfully';
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => HomeScreen()));
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Invalid login credentials")));
    }
  }

  @override
  void initState() {
    _authStateSubscription = supabase.auth.onAuthStateChange.listen(
      (data) {
        if (_redirecting) return;
        final session = data.session;
        if (session != null) {
          _redirecting = true;
          setState(() async {
            userIs = true;
            _redirecting = false;

            Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => HomeScreen()));
          });
        }
      },
      onError: (error) {
        if (error is AuthException) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.message)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("An internal error occurred")));
        }
      },
    );
    super.initState();
  }

  bool _validateEmail(String email) {
    return email.endsWith('@gg.in');
  }

  bool _validatePassword(String password) {
    return RegExp(r'^\d{6}$').hasMatch(password); // Only 6 digits
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'User@gg.in',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
              keyboardType: TextInputType.number,
              // Numeric keyboard
              maxLength: 6, // Limit to 6 characters
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                if (_validateEmail(_emailController.text) &&
                    _validatePassword(_passwordController.text)) {
                  _isSignUp ? _signUp() : _signIn();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Invalid email or password format'),
                  ));
                }
              },
              child: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  _isSignUp = !_isSignUp;
                });
              },
              child: Text(_isSignUp
                  ? 'Already have an account? Sign In'
                  : 'Don\'t have an account? Sign Up'),
            ),
            SizedBox(height: 16.0),
            Text(_message, style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  insertUser() async {}
}
