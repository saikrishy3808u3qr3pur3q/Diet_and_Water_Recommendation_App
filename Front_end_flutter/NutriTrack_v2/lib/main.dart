import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nutritrack_v2/views/update_view.dart';
import 'package:provider/provider.dart';
import 'package:nutritrack_v2/views/homepage_view.dart';
//import 'package:nutritrack_v2/views/signup_view.dart';
//import 'package:nutritrack_v2/views/login_view.dart';
import 'package:nutritrack_v2/viewmodels/auth_viewmodel.dart';
import 'package:nutritrack_v2/viewmodels/user_details_viewmodel.dart';
import 'core/services/firebase_options.dart';
import 'views/dashboard_view.dart';
import 'views/water_intake_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthViewModel()),
        ChangeNotifierProvider(create: (context) => UserDetailsViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeView(), // Set HomeView as the initial route
      routes: {
        '/mainApp': (context) => const MainApp(), // Define a route for MainApp
      },
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  MainAppState createState() => MainAppState(); // Remove the underscore
}

class MainAppState extends State<MainApp> { // Remove the underscore
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const DashboardView(),
    const WaterIntakeView(),
    UpdateView(),
    // Add other views here if needed
  ];

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Food"),
          BottomNavigationBarItem(icon: Icon(Icons.local_drink), label: "Water"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromRGBO(232, 134, 7, 1),
        onTap: _onTabTapped,
      ),
    );
  }
}