// import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:madee_share/pages/activity_feed.dart';
import 'package:madee_share/pages/create_account.dart';
import 'package:madee_share/pages/profile.dart';
import 'package:madee_share/pages/register.dart';
import 'package:madee_share/pages/search.dart';
import 'package:madee_share/pages/timeline.dart';
import 'package:madee_share/pages/upload.dart';
import 'package:madee_share/widgets/progress.dart';

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

TextEditingController emailController = TextEditingController(text: '');
TextEditingController passwordController = TextEditingController(text: '');

FirebaseAuth _auth = FirebaseAuth.instance;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;
  bool isLoading = false;
  PageController? pageController;
  int pageIndex = 0;

  @override
  initState() {
    super.initState();
    pageController = PageController();

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      cekLoginEmail(user.uid);
    }

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

  cekLoginEmail(String id) async {
    await getDataLoginWithEmail(id);
    setState(() {
      isAuth = true;
    });
  }

  getDataLoginWithEmail(String id) async {
    DocumentSnapshot snapshot = await usersRef.doc(id).get();
    currentUser = UserModel.fromDocument(snapshot);
  }

  @override
  void dispose() {
    pageController?.dispose();
    super.dispose();
  }

  Future<bool> loginHandle() async {
    setState(() {
      isLoading = true;
    });
    if (emailController.text == "" ||
        passwordController.text == "" ||
        emailController.text == null ||
        passwordController.text == null) {
      return false;
    }
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text, password: passwordController.text);

    if (userCredential.user == null) {
      return false;
    }

    DocumentSnapshot snapshot =
        await usersRef.doc(userCredential.user!.uid).get();
    currentUser = UserModel.fromDocument(snapshot);
    setState(() {
      isAuth = true;
    });

    return true;
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
        "loginWith": "google",
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
              margin: EdgeInsets.only(top: 60),
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
            Padding(
              padding: EdgeInsets.only(top: 30, left: 20, right: 20),
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white60.withOpacity(.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black54.withOpacity(.2),
                      spreadRadius: 3,
                      blurRadius: 2,
                      offset: Offset(-2, 2),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    Container(
                      margin: EdgeInsets.only(left: 15, right: 15, top: 20),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Email'),
                          TextFormField(
                            controller: emailController,
                            cursorColor: Colors.black,
                            decoration: InputDecoration(
                              hintText: "Your Email",
                              hintStyle: TextStyle(color: Colors.grey),
                              focusColor: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 15, right: 15, top: 20),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Password'),
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            cursorColor: Colors.black,
                            decoration: InputDecoration(
                              hintText: "Your Password",
                              hintStyle: TextStyle(color: Colors.grey),
                              focusColor: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    isLoading
                        ? Container(
                            margin:
                                EdgeInsets.only(left: 15, right: 15, top: 20),
                            width: 100,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              onPressed: () {},
                              child: circularProgress(),
                            ),
                          )
                        : Container(
                            margin:
                                EdgeInsets.only(left: 15, right: 15, top: 20),
                            width: 100,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              onPressed: () async {
                                if (await loginHandle()) {
                                } else {
                                  Fluttertoast.showToast(msg: "login failed");
                                }
                              },
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                    Container(
                      margin: EdgeInsets.only(left: 15, right: 15, top: 20),
                      width: double.infinity,
                      child: Row(
                        children: [
                          Text('Dont Have an Account?'),
                          SizedBox(
                            width: 10,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => RegisterPage()));
                            },
                            child: Text('Register',
                                style: TextStyle(
                                  color: Colors.red,
                                )),
                          )
                        ],
                      ),
                    ),
                  ],
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
