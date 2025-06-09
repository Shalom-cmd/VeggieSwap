import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // List of motivational quotes
  final List<String> quotes = [
    "The food you eat can be either the safest and most powerful form of medicine or the slowest form of poison.",
    "Every time you eat is an opportunity to nourish your body.",
    "Being vegan isn’t about being perfect. It’s about being better for ourselves, animals, and the planet.",
    "Let food be thy medicine and medicine be thy food.",
    "It’s not a diet, it’s a lifestyle."
  ];

  // Function to get a random quote
  String getRandomQuote() {
    final random = Random();
    return quotes[random.nextInt(quotes.length)];
  }

  // Navigate to the login screen
  void _goToLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login');
  }

  // Navigate to the user profile screen
  void _goToProfile(BuildContext context) {
    Navigator.pushNamed(context, '/profile');
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Start Your Journey Today!'),
      actions: [
        _auth.currentUser != null
            ? Row(
                children: [
                  Text(
                    _auth.currentUser!.displayName ?? 'User',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _goToProfile(context),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: _auth.currentUser?.photoURL != null
                          ? NetworkImage(_auth.currentUser!.photoURL!)
                          : null,
                      child: _auth.currentUser?.photoURL == null
                          ? Icon(Icons.person, size: 24)
                          : null,
                    ),
                  ),
                ],
              )
            : IconButton(
                icon: Icon(Icons.login),
                onPressed: () => _goToLogin(context),
              ),
      ],
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
    ),
    drawer: Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0), 
              child: Align(
                alignment: Alignment.centerLeft, 
                child: Text(
                  'Start Your Journey Today',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20, 
                  ),
                ),
              ),
            ),
            padding: EdgeInsets.all(0), 
          ),
          ListTile(
            title: Text('Search'),
            onTap: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
          ListTile(
            title: Text('Your Favorite Recipes'),
            onTap: () {
              Navigator.pushNamed(context, '/favorites');
            },
          ),

          ListTile(
            title: Text('Your Shopping List'),
            onTap: () {
              Navigator.pushNamed(context, '/shopping-list');
            },
          ),
          ListTile(
            title: Text('Document Your Journey'),
            onTap: () {
              Navigator.pushNamed(context, '/document-your-journey');
            },
          ),          
          ListTile(
            title: Text('Pin Your Favortie Locations'),
            onTap: () {
              Navigator.pushNamed(context, '/location');
            },
          ),
          ListTile(
            title: Text('Logout'),
            onTap: () async {
              await _auth.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    ),
    body: Center(  
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,  
          crossAxisAlignment: CrossAxisAlignment.center,  
          children: [
            // App Title
            Text(
              'VEGGIE SWAP',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,  
            ),
            SizedBox(height: 40),

            // Mission Statement
            Text(
              'Our Mission:',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.green[800],
              ),
              textAlign: TextAlign.center,  
            ),
            SizedBox(height: 10),
            Text(
              'Our mission is to empower vegans and vegetarians by providing a seamless platform to discover delicious and nutritious food substitutes.\nWe aim to make plant-based eating easier, more accessible, and enjoyable, helping users make informed choices that align with their values and lifestyle',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,  // Center the mission text
            ),
            SizedBox(height: 30),

            // Motivational Quote
            Card(
              elevation: 3,
              color: Colors.green[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,  // Center content inside the card
                  children: [
                    Icon(Icons.format_quote, color: Colors.green, size: 30),
                    SizedBox(height: 10),
                    Text(
                      getRandomQuote(), // Display a random quote
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: Colors.green[900],
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "- Stay Inspired -",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Login/Signup Buttons (if user not logged in)
            if (_auth.currentUser == null) ...[
              Center(
                child: ElevatedButton(
                  onPressed: () => _goToLogin(context),
                  child: Text('Login'),
                ),
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: Text('Sign Up'),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
}