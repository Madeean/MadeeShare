import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:madee_share/models/user_model.dart';
import 'package:madee_share/pages/home.dart';
import 'package:madee_share/widgets/header.dart';
import 'package:madee_share/widgets/progress.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController displaynameController = TextEditingController(text: '');
  TextEditingController usernameController = TextEditingController(text: '');
  TextEditingController emailController = TextEditingController(text: '');
  TextEditingController passwordController = TextEditingController(text: '');

  bool isloading = false;

  FirebaseAuth _auth = FirebaseAuth.instance;
  final usersRef = FirebaseFirestore.instance.collection('users');

  final DateTime timestamp = DateTime.now();

  Future<bool> registerHandle(context) async {
    setState(() {
      isloading = true;
    });
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text, password: passwordController.text);

    if (userCredential.user == null) {
      return false;
    }

    String photoUrl =
        "https://avatars.abstractapi.com/v1/?api_key=f4964acb34534e2cb2e20829efac27d2&name=${usernameController.text}";
    String bio = "";

    UserModel user = UserModel(
      id: userCredential.user!.uid,
      username: usernameController.text,
      email: emailController.text,
      photoUrl: photoUrl,
      displayName: displaynameController.text,
      bio: bio,
    );

    await usersRef.doc(userCredential.user!.uid).set({
      "id": userCredential.user!.uid,
      "username": usernameController.text,
      "email": emailController.text,
      "photoUrl": photoUrl,
      "displayName": displaynameController.text,
      "bio": bio,
      "timestampt": timestamp,
      "loginWith": "email",
    });

    return true;
  }

  @override
  Widget build(BuildContext context) {
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
        child: SafeArea(
          child: ListView(
            children: [
              Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(left: 20, right: 20),
                    padding: EdgeInsets.only(top: 10, left: 10),
                    decoration: BoxDecoration(
                      color: Colors.white60,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    width: double.infinity,
                    height: 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Display Name'),
                        SizedBox(
                          height: 10,
                        ),
                        TextFormField(
                          controller: displaynameController,
                          cursorColor: Colors.black,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Your Display Name",
                            hintStyle: TextStyle(color: Colors.grey),
                            focusColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 20, right: 20, top: 20),
                    padding: EdgeInsets.only(top: 10, left: 10),
                    decoration: BoxDecoration(
                      color: Colors.white60,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    width: double.infinity,
                    height: 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Username'),
                        SizedBox(
                          height: 10,
                        ),
                        TextFormField(
                          controller: usernameController,
                          cursorColor: Colors.black,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Your Username",
                            hintStyle: TextStyle(color: Colors.grey),
                            focusColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 20, right: 20, top: 20),
                    padding: EdgeInsets.only(top: 10, left: 10),
                    decoration: BoxDecoration(
                      color: Colors.white60,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    width: double.infinity,
                    height: 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email'),
                        SizedBox(
                          height: 10,
                        ),
                        TextFormField(
                          controller: emailController,
                          cursorColor: Colors.black,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Your Email",
                            hintStyle: TextStyle(color: Colors.grey),
                            focusColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(left: 20, right: 20, top: 20),
                    padding: EdgeInsets.only(top: 10, left: 10),
                    decoration: BoxDecoration(
                      color: Colors.white60,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    width: double.infinity,
                    height: 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Password'),
                        SizedBox(
                          height: 10,
                        ),
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          cursorColor: Colors.black,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Your Password",
                            hintStyle: TextStyle(color: Colors.grey),
                            focusColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  isloading
                      ? Container(
                          margin: EdgeInsets.only(top: 20),
                          width: 150,
                          height: 50,
                          child: MaterialButton(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                18,
                              ),
                            ),
                            color: Colors.blue,
                            onPressed: () async {
                              if (await registerHandle(context)) {
                                Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Home()),
                                    (route) => false);
                              } else {
                                Fluttertoast.showToast(msg: "register failed");
                                setState(() {
                                  isloading = false;
                                });
                              }
                            },
                            child: circularProgress(),
                          ),
                        )
                      : Container(
                          margin: EdgeInsets.only(top: 20),
                          width: 150,
                          height: 50,
                          child: MaterialButton(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                18,
                              ),
                            ),
                            color: Colors.blue,
                            onPressed: () async {
                              if (await registerHandle(context)) {
                                Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Home()),
                                    (route) => false);
                              } else {
                                Fluttertoast.showToast(msg: "register failed");
                                setState(() {
                                  isloading = false;
                                });
                              }
                            },
                            child: Text('Register'),
                          ),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
