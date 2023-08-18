import 'package:flutter/material.dart';
import 'package:mata_uang/home_page_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pendeteksi Mata Uang',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePageScreen(title: 'Mata Uang'),
      debugShowCheckedModeBanner: false,
    );
  }
}
