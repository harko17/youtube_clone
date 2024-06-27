import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube/home%20screen/home_screen.dart';
import 'package:supabase/supabase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://oejwazbjlcsayyzpknmg.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9landhemJqbGNzYXl5enBrbm1nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTkyMTAxNzUsImV4cCI6MjAzNDc4NjE3NX0.SIDsFvHI-qTUKRjFyjxzi_540Bl089j3r0rcL6yyKwQ",
  );

  runApp(MyApp());
}
final supabase = Supabase.instance.client;
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(


        useMaterial3: true,
      ),
      home: HomeScreen(),
    );
  }
}
