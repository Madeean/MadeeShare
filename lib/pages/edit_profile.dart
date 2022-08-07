import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import "package:flutter/material.dart";
import 'package:madee_share/models/user_model.dart';
import 'package:madee_share/pages/home.dart';
import 'package:madee_share/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;
  EditProfile({required this.currentUserId});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  bool isLoading = false;
  UserModel? user;
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool _displayNameValid = true;
  bool _bioValid = true;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

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
    DocumentSnapshot doc = await usersRef.doc(widget.currentUserId).get();

    user = UserModel.fromDocument(doc);
    displayNameController.text = user!.displayName;
    bioController.text = user!.bio;
    Timer(Duration(seconds: 1), () {
      setState(() {
        isLoading = false;
      });
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
            errorText: _displayNameValid ? null : "DisplayName too short",
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
            errorText: _bioValid ? null : "bio too long",
          ),
        )
      ],
    );
  }

  updatedProfileData() {
    setState(() {
      displayNameController.text.trim().length < 3 ||
              displayNameController.text.isEmpty
          ? _displayNameValid = false
          : _displayNameValid = true;

      bioController.text.trim().length > 100
          ? _bioValid = false
          : _bioValid = true;

      if (_displayNameValid && _bioValid) {
        usersRef.doc(widget.currentUserId).update({
          "displayName": displayNameController.text,
          "bio": bioController.text,
        });
        SnackBar snackBar = SnackBar(content: Text("profile updated"));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        Timer(Duration(seconds: 1), () => Navigator.pop(context));
      }
    });
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  navi(context) {}

  @override
  Widget build(BuildContext context) {
    logout() async {
      FirebaseAuth _auth = FirebaseAuth.instance;
      DocumentSnapshot doc = await usersRef.doc(widget.currentUserId).get();
      print("DOC ${doc['loginWith']}");
      // await googleSignIn.disconnect();
      print("p");

      if (doc['loginWith'] == "email") {
        await _auth.signOut();
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (context) => Home()), (route) => false);
      } else {
        await googleSignIn.disconnect();
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (context) => Home()), (route) => false);
      }

      // print("p1");
      // await _auth.signOut();
      // print("p2");
      // navi(context);
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(
          color: Colors.black,
        ),
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
              onPressed: updatedProfileData,
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
                          backgroundImage: NetworkImage(user!.photoUrl),
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
                      // MaterialButton(
                      //   onPressed: updatedProfileData,
                      //   shape: RoundedRectangleBorder(
                      //     borderRadius: BorderRadius.circular(8),
                      //   ),
                      //   color: Colors.white,
                      //   child: Text(
                      //     'Update Profile',
                      //     style: TextStyle(
                      //       color: Theme.of(context).primaryColor,
                      //       fontSize: 20,
                      //       fontWeight: FontWeight.bold,
                      //     ),
                      //   ),
                      // ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: TextButton.icon(
                          onPressed: logout,
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
