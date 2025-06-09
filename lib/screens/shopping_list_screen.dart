import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShoppingListScreen extends StatefulWidget {
  @override
  _ShoppingListScreenState createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final TextEditingController _controller = TextEditingController();
  
  String get userId => FirebaseAuth.instance.currentUser?.uid ?? 'default_user'; // Replace with actual user ID if using authentication

  void _addItem() async {
    String newItem = _controller.text.trim();
    if (newItem.isNotEmpty) {
      // Add the new item to Firestore
      await FirebaseFirestore.instance.collection('shoppingList').doc(userId).set({
        'items': FieldValue.arrayUnion([{'name': newItem}]),
      }, SetOptions(merge: true));

      // Clear the input field
      _controller.clear();
      Navigator.pop(context);  // Close the dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    final shoppingListStream = FirebaseFirestore.instance.collection('shoppingList').doc(userId).snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping List'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: shoppingListStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return Center(child: Text('Your Shopping List is Empty!'));
          }
          final shoppingList = List<Map<String, dynamic>>.from(snapshot.data!['items'] ?? []);

          return ListView.builder(
            itemCount: shoppingList.length,
            itemBuilder: (context, index) {
              final item = shoppingList[index];
              return ListTile(
                title: Text(
                  item['name'],
                  style: TextStyle(fontSize: 20),  // Set the font size here
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('shoppingList').doc(userId).set({
                      'items': FieldValue.arrayRemove([item]),
                    }, SetOptions(merge: true));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Add Item'),
                content: TextField(
                  controller: _controller,
                  decoration: InputDecoration(hintText: 'Enter item name'),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                    },
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: _addItem,
                    child: Text('Add'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      ),
    );
  }
}
