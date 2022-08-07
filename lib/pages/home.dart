// import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:madee_share/pages/activity_feed.dart';
import 'package:madee_share/pages/create_account.dart';
import 'package:madee_share/pages/profile.dart';
import 'package:madee_share/pages/search.dart';
import 'package:madee_share/pages/timeline.dart';
import 'package:madee_share/pages/upload.dart';

import '../models/user_model.dart';

final GoogleSignIn googleSignIn = GoogleSignIn();
final Reference storageRef = FirebaseStorage.instance.ref();

final usersRef = FirebaseFirestore.instance.collection('users');
final postRef = FirebaseFirestore.instance.collection('posts');
final commentsRef = FirebaseFirestore.instance.collection('comments');
final activityFeedRef = FirebaseFirestore.instance.collection('feed');
final followersRef = FirebaseFirestore.instance.collection('followers');
final followingRef = FirebaseFirestore.instance.collection('following');
final timelineRef = FirebaseFirestore.instance.collection('timeline');
final DateTime timestamp = DateTime.now();
UserModel? currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;
  PageController? pageController;
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    // detect sign in
    googleSignIn.onCurrentUserChanged.listen((account) {
      if (account == null) {
        print("accoutn sign in null");
      } else {
        handleSignin(account);
      }
    }, onError: (error) {
      print("error : $error");
    });

    // reauthenticate user when user was sign in previously
    googleSignIn.signInSilently(suppressErrors: false).then((account) {
      if (account == null) {
        print("accoutn sign in silent null");
      } else {
        handleSignin(account);
      }
    }).catchError((err) {
      print(err);
    });
  }

  @override
  void dispose() {
    pageController?.dispose();
    super.dispose();
  }

  handleSignin(GoogleSignInAccount account) async {
    if (account != null) {
      await createUserInFirestore();
      setState(() {
        isAuth = true;
      });
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  createUserInFirestore() async {
    // if check user exist in users collection di database
    final GoogleSignInAccount? user = googleSignIn.currentUser;
    DocumentSnapshot doc = await usersRef.doc(user?.id).get();
    // print("udh punya akun? ${doc.exists}");

    if (!doc.exists) {
      // if the user doesnt exist ,  then we wan to take them to create account page

      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));
      // get username from create account, use it to make new user document in users collenction

      usersRef.doc(user?.id).set({
        "id": user?.id,
        "username": username,
        "photoUrl": user?.photoUrl,
        "email": user?.email,
        "displayName": user?.displayName,
        "bio": "",
        "timestamp": timestamp,
      });

      await followersRef
          .doc(user?.id)
          .collection('userFollower')
          .doc(user?.id)
          .set({});

      doc = await usersRef.doc(user?.id).get();
    }

    currentUser = UserModel.fromDocument(doc);
  }

  login() async {
    await googleSignIn.signIn();
  }

  logout() {
    googleSignIn.signOut();
  }

  onPageChanged(int pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(int pageIndex) {
    pageController?.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  Scaffold buildAuthScreen() {
    return Scaffold(
      body: PageView(
        children: [
          Timeline(currentUser: currentUser!),
          ActivityFeed(),
          Upload(
            currentUser: currentUser!,
          ),
          Search(),
          Profile(profileId: currentUser!.id),
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        onTap: onTap,
        activeColor: Theme.of(context).primaryColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.whatshot),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.photo_camera,
              size: 35.0,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
          ),
        ],
      ),
    );
    // return TextButton(
    //   onPressed: logout,
    //   child: Text('Logout'),
    // );
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).colorScheme.secondary.withOpacity(0.6),
              Theme.of(context).primaryColor,
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 1,
              alignment: Alignment.center,
              child: Text(
                'MadeeShare',
                style: TextStyle(
                  fontFamily: "Signatra",
                  fontSize: 70,
                  color: Colors.white,
                ),
                maxLines: 1,
              ),
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 260,
                height: 60,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/images/google_signin_button.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
