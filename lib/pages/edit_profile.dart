import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:social_network_flutter/models/user.dart';
import 'package:social_network_flutter/pages/home.dart';
import 'package:social_network_flutter/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;
  EditProfile({this.currentUserId});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  bool isLoading = false;
  User user;
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot doc = await usersRef.document(widget.currentUserId).get();
    print(doc.data);

    user = User.fromDocument(doc);
    displayNameController.text = user.displayName;
    bioController.text = user.bio;
    setState(() {
      isLoading = false;
    });
  }

  Column buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Display Name',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
            hintText: "update display name",
          ),
        )
      ],
    );
  }

  Column buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Bio',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
            hintText: "update bio",
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
              padding: EdgeInsets.only(right: 20),
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.done,
                size: 30,
                color: Colors.green,
              )),
        ],
      ),
      body: isLoading
          ? circularProgress()
          : ListView(
              children: [
                Container(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          top: 16,
                          bottom: 8,
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(user.photoUrl),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            buildDisplayNameField(),
                            buildBioField(),
                          ],
                        ),
                      ),
                      MaterialButton(
                        onPressed: () => print('update'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        color: Colors.white,
                        child: Text(
                          'Update Profile',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: TextButton.icon(
                          onPressed: () => print('logout'),
                          icon: Icon(
                            Icons.cancel,
                            color: Colors.red,
                          ),
                          label: Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
