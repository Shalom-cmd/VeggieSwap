import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';


import 'package:veggie_swap/screens/auth_check.dart';
import 'package:veggie_swap/screens/login_screen.dart';
import 'package:veggie_swap/screens/signup_screen.dart';
import 'package:veggie_swap/screens/home_screen.dart';
import 'package:veggie_swap/screens/profile_screen.dart';
import 'package:veggie_swap/screens/favorites_screen.dart';
import 'package:veggie_swap/screens/location_screen.dart';
import 'package:veggie_swap/screens/search_screen.dart';
import 'package:veggie_swap/screens/shopping_list_screen.dart';
import 'package:veggie_swap/screens/document_your_journey_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp( 
    options: DefaultFirebaseOptions.currentPlatform,
    );// Initialize Firebase
  runApp(VeggieSwapApp());
}

class VeggieSwapApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Veggie Swap',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      initialRoute: '/login',
      routes: {
        '/': (context) => HomeScreen(),  // Home screen route
        '/profile': (context) => ProfileScreen(), // Profile screen
        '/login': (context) => LoginScreen(), 
        '/signup': (context) => SignUpScreen(), 
        '/search': (context) => SearchScreen(),
        '/favorites': (context) => FavoritesScreen(),
        '/location': (context) => LocationScreen(),
        '/shopping-list': (context) => ShoppingListScreen(),
        '/document-your-journey': (context) => DocumentYourJourneyScreen()


      },
    );
  }
}

