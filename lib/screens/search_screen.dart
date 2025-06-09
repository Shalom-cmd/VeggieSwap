import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _recipes = [];
  List<Map<String, dynamic>> _shoppingList = [];

  final String appId = 'c11863e3';  // Your Edamam App ID
  final String apiKey = '1ccc337f7484d86ce5447ae1ea22ea60';  // Your Edamam API Key

  Future<void> _fetchSearchResults(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('foodsubs')
          .doc(query)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data();
        final substitutes = List<Map<String, dynamic>>.from(data?['substitutes'] ?? []);
        setState(() {
          _searchResults = substitutes;
        });
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    } catch (e) {
      print("Error fetching search results: $e");
    }
  }

  Future<void> _fetchRecipes(String ingredient) async {
    final url =
        'https://api.edamam.com/api/recipes/v2?type=public&q=$ingredient&app_id=$appId&app_key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _recipes = List<Map<String, dynamic>>.from(data['hits']?.map((hit) => {
            'label': hit['recipe']['label'],
            'image': hit['recipe']['image'],
            'url': hit['recipe']['url'],
          }) ?? []);
        });
      } else {
        print("Failed to load recipes");
      }
    } catch (e) {
      print("Error fetching recipes: $e");
    }
  }

  
  Future<void> _saveToFavorites(Map<String, dynamic> recipe) async {
    try {
      // Get the current user's ID
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'default_user';

      // Reference to the 'favorites' collection for the current user
      final favoritesCollection = FirebaseFirestore.instance.collection('favorites');

      // Add the recipe as a new document in the favorites collection
      await favoritesCollection.add({
        'userId': userId, 
        'label': recipe['label'], 
        'url': recipe['url'], 
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${recipe['label']} added to favorites!')),
      );
    } catch (e) {
      print("Error saving to favorites: $e");
    }
  }
  Future<void> _addToShoppingList(Map<String, dynamic> substitute) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'default_user'; 
      final shoppingListCollection = FirebaseFirestore.instance.collection('shoppingList').doc(userId);

      // Add the item to the shopping list for the current user
      await shoppingListCollection.set({
        'items': FieldValue.arrayUnion([substitute]),
      }, SetOptions(merge: true));

      // Update the local list
      setState(() {
        _shoppingList.add(substitute);
      });

      // Show a confirmation SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${substitute['name']} added to shopping list!')),
      );
    } catch (e) {
      print("Error adding to shopping list: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to shopping list!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search for Vegan/Vegetarian Substitutes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for products, add products to cart, view recipes, add recipes to favorites...',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    setState(() {
                      _searchQuery = _searchController.text.trim();
                    });
                    _fetchSearchResults(_searchQuery);
                  },
                ),
              ),
              onSubmitted: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
                _fetchSearchResults(_searchQuery);
              },
            ),
            SizedBox(height: 20),
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'Enter a product name to start searching. Our database currently holds substitutes for meat, milk, and eggs. More will be added soon.'
                            : 'No results found for "$_searchQuery". Try searching for Milk, Meat or Eggs substitutes.\nWe are working on adding more substitutes, thank you for your patience :)',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          title: Text(result['name'] ?? 'Unnamed substitute'),
                          subtitle: Text(
                            '${result['calories']} calories, '
                            '${result['protein']} protein\n'
                            '${result['description']}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.book),
                                onPressed: () {
                                  _fetchRecipes(result['name']);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.shopping_cart_sharp, color: Colors.red),
                                onPressed: () {
                                  _addToShoppingList(result);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (_recipes.isNotEmpty) ...[
              SizedBox(height: 20),
              Text(
                'Try creating some of the recipes below:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = _recipes[index];
                    return ListTile(
                      title: Text(recipe['label']),
                      leading: Icon(Icons.restaurant, size: 40.0),
                      trailing: IconButton(
                        icon: Icon(Icons.favorite_border, color: Colors.red),
                        onPressed: () {
                          _saveToFavorites(recipe);
                        },
                      ),
                      onTap: () {
                        _launchURL(recipe['url']);
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}



