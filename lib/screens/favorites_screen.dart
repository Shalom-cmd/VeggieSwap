import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get the current user ID from FirebaseAuth
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'default_user';

    // Reference to the 'favorites' collection for the current user
    final favoritesStream = FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: userId) // Filter favorites by the current user's ID
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: favoritesStream, // Stream for the 'favorites' collection filtered by userId
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // Fixing the nullable bool issue by adding '?? true' if snapshot data is null
          if (!snapshot.hasData || (snapshot.data?.docs.isEmpty ?? true)) {
            return Center(child: Text('No favorites yet!'));
          }

          // Get the favorite items from the snapshot
          final favorites = snapshot.data?.docs ?? [];

          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final favorite = favorites[index].data() as Map<String, dynamic>;
              final favoriteId = favorites[index].id;

              return ListTile(
                leading: Icon(Icons.restaurant, color: Colors.green),
                title: Text(favorite['label']),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    // Delete the favorite item
                    await FirebaseFirestore.instance
                        .collection('favorites')
                        .doc(favoriteId) // Reference to the specific favorite
                        .delete();
                  },
                ),
                onTap: () {
                  // Optional: Launch recipe URL
                  if (favorite['url'] != null) {
                    _launchURL(favorite['url']);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  // Launch URL function
  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }
}
