import 'dart:html' as html;
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DocumentYourJourneyScreen extends StatefulWidget {
  @override
  _DocumentYourJourneyScreenState createState() =>
      _DocumentYourJourneyScreenState();
}

class _DocumentYourJourneyScreenState
    extends State<DocumentYourJourneyScreen> {
  Uint8List? _imageBytes;
  String? _imageUrl;
  final TextEditingController _descriptionController = TextEditingController();
  String _timestamp = '';

  // Change the type to List<Map<String, dynamic>> to allow various data types
  List<Map<String, dynamic>> uploadedImages = [];

  @override
  void initState() {
    super.initState();
    _loadUploadedImages(); // Load images when the screen is loaded
  }

  // Fetch uploaded images and their descriptions from Firestore
  Future<void> _loadUploadedImages() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshots = await FirebaseFirestore.instance
          .collection('journeyDocs')
          .doc(user.uid)
          .collection('uploads')
          .get();

      setState(() {
        uploadedImages = snapshots.docs.map((doc) {
          return {
            'imageUrl': doc['imageUrl'],
            'description': doc['description'],
            'timestamp': doc['timestamp'],
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching images: $e');
    }
  }

  // Function to pick an image file
  void _pickImage() async {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
    uploadInput.accept = 'image/*'; // Allow only image files
    uploadInput.click(); // Trigger the file selection dialog

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files?.isEmpty ?? true) return;
      final file = files?.first;
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file!); // Read the file as raw bytes

      reader.onLoadEnd.listen((e) {
        setState(() {
          _imageBytes = reader.result as Uint8List; // Store image as bytes
          _timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
        });
      });
    });
  }

  // Function to upload image to Firebase Storage and Firestore
  Future<void> _uploadImage() async {
    try {
      // Ensure the user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You must be logged in to upload an image.')),
        );
        return;
      }

      // Ensure an image is selected and a description is provided
      if (_imageBytes == null || _descriptionController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select an image and provide a description!')),
        );
        return;
      }

      // Create a reference to Firebase Storage for the image
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Upload the image data to Firebase Storage
      final uploadTask = storageRef.putData(
        _imageBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Wait for the upload to complete and get the download URL
      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      // Save the image URL and description to Firestore
      await FirebaseFirestore.instance
          .collection('journeyDocs')
          .doc(user.uid)
          .collection('uploads')
          .add({
        'description': _descriptionController.text,
        'imageUrl': imageUrl,
        'timestamp': _timestamp,
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload successful!')));

      // Reset the state and reload images
      setState(() {
        _imageBytes = null;
        _descriptionController.clear();
      });

      _loadUploadedImages(); // Reload the uploaded images
    } catch (e) {
      print('Error during upload: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image! Error: $e')));
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Document Your Journey'),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructional Text below the title with Card and Icon
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF16AC1C)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'To document your journey, add a photo of a meal you made.\nIn the description list the ingredients you used, where you purchased them from and then rate the meal out of 10.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF16AC1C),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20), // Adds spacing between the text and the rest of the content
          
          // Button to pick an image
          ElevatedButton(
            onPressed: _pickImage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.black, // Set the button's text color
            ),
            child: Text('Pick an image from your gallery'),
          ),
          SizedBox(height: 20),
          
          // Display the selected image
          _imageBytes != null
              ? Image.memory(
                  _imageBytes!,
                  height: 300, // Limiting the height of the image
                  width: double.infinity, // Make it responsive
                  fit: BoxFit.contain, // Ensure no cropping
                )
              : Text('No image selected'),
          SizedBox(height: 20),
          
          // Description input field
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'Enter Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          SizedBox(height: 20),
          
          // Upload button
          ElevatedButton(
            onPressed: _uploadImage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.black, // Set the button's text color
            ),
            child: Text('Upload your image'),
          ),
          SizedBox(height: 20),
          
          // Uploaded Images section with Card and Icon
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.photo_album, color: Color(0xFF16AC1C)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Uploaded Images:\nClick the button to view your uploaded images!',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF16AC1C),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          
          // Display previously uploaded images
          uploadedImages.isEmpty
              ? Text('No images uploaded yet.')
              : Expanded(
                  child: ListView.builder(
                    itemCount: uploadedImages.length,
                    itemBuilder: (context, index) {
                      final imageData = uploadedImages[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            // Use a button instead of an icon
                            InkWell(
                              onTap: () {
                                // Open the image URL in a new tab
                                html.window.open(imageData['imageUrl'], '_blank');
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Open the image URL in a new tab
                                    html.window.open(imageData['imageUrl'], '_blank');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 32.0), // Increase size
                                    textStyle: TextStyle(fontSize: 18), // Increase text size
                                    backgroundColor: Colors.blue,
                                  ),
                                  child: Text('Click to view image'),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                imageData['description'],
                                style: TextStyle(fontSize: 16), // Adjust description text size
                                textAlign: TextAlign.center, // Center description text
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    ),
  );
}
}