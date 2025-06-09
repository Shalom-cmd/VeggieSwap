import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';

Future<void> _signUp() async {
  try {
    // Check if the form is valid
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      // Debug: Log password values
      print("Password: $_password");
      print("Confirm Password: $_confirmPassword");

      // Ensure passwords match
      if (_password != _confirmPassword) {
        print("Passwords do not match");
        throw Exception('Passwords do not match');
      }

      // Create a user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _email,
        password: _password,
      );

      // If user is created successfully, update the user's name
      await userCredential.user?.updateDisplayName(_name);

      // Save user data to Firestore
      await _firestore
          .collection('users') // Reference to the 'users' collection
          .doc(userCredential.user?.uid) // Reference to the specific user's document
          .collection('userInfo') // Reference to the 'userInfo' subcollection
          .add({
        'uid': userCredential.user?.uid,  // Store the user ID in the subcollection
        'name': _name,                    // Store the username
        'email': _email,                  // Store the email
      });

      // Navigate to HomeScreen or any other screen after sign-up
      Navigator.pushReplacementNamed(context, '/');
    }
  } catch (e) {
    // Handle any errors that occur during sign-up
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Name input
              TextFormField(
                decoration: InputDecoration(labelText: 'Full Name'),
                onSaved: (value) {
                  _name = value ?? '';
                },
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              // Email input
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                onSaved: (value) {
                  _email = value ?? '';
                },
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              // Password input
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                onSaved: (value) {
                  _password = value ?? '';
                },
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
                onSaved: (value) {
                  _confirmPassword = value ?? '';
                },
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please confirm your password';
                  }
                  return null; // Validation of matching happens in `_signUp`
                },
              ),
              SizedBox(height: 20),
              // Sign Up Button
              ElevatedButton(
                onPressed: _signUp,
                child: Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
