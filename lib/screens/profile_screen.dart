import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to log the user out
  void _logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login'); // Navigate back to login screen
  }

  @override
  Widget build(BuildContext context) {
    // Get current user data
    User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Display profile picture or default if not set
            CircleAvatar(
              radius: 50,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null, // No image if photoURL is null
              child: user?.photoURL == null 
                  ? Icon(Icons.account_circle, size: 50)  // Use an icon as a fallback
                  : null,  // No icon if photoURL is not null
              ),
            SizedBox(height: 20),
            // Display user's name (or default message if not available)
            Text(
              user?.displayName ?? 'Guest',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            // Display user's email
            Text(
              user?.email ?? 'No email available',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 30),
            // Button to log out
            ElevatedButton(
              onPressed: () => _logout(context),
              child: Text('Log Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Red button for logout
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
