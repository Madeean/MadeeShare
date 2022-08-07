import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:madee_share/models/user_model.dart';
import 'package:madee_share/pages/home.dart';
import 'package:madee_share/pages/search.dart';
import 'package:madee_share/widgets/header.dart';
import 'package:madee_share/widgets/post.dart';
import 'package:madee_share/widgets/progress.dart';

final usersRef = FirebaseFirestore.instance.collection('users');

class Timeline extends StatefulWidget {
  final UserModel currentUser;

  Timeline({required this.currentUser});

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  // List<dynamic> users = [];

  List<Post>? posts;
  List<String> followingList = [];

  @override
  void initState() {
    // TODO: implement initState
    // getUsers();

    // getUserById();
    // createUser();
    // updateUser();
    // deleteUser();
    super.initState();
    getTimeline();
    getFollowing();
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .doc(currentUser?.id)
        .collection('userFollowing')
        .get();
    setState(() {
      followingList = snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  // documents.map((doc) => doc.documentID).toList();
  getTimeline() async {
    QuerySnapshot snapshot = await timelineRef
        .doc(widget.currentUser.id)
        .collection('timelinePosts')
        .orderBy('timestamp', descending: true)
        .get();

    List<Post> posts =
        snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    setState(() {
      this.posts = posts;
    });
  }

  createUser() {
    usersRef.doc("asdawdf").set({
      "username": "zoro",
      "postscount": 5,
      "isAdmin": false,
    });
  }

  updateUser() async {
    final doc = await usersRef.doc("6hu7Z9WVtxEQuU7noaLb").get();
    if (doc.exists) {
      doc.reference
          .update({"username": "zoroax", "postscount": 5, "isAdmin": false});
    }
    // .updateData({"username": "zoroax", "postscount": 5, "isAdmin": false});
  }

  deleteUser() async {
    final doc = await usersRef.doc("6hu7Z9WVtxEQuU7noaLb").get();

    if (doc.exists) {
      doc.reference.delete();
    }
  }

  // getUserById() async {
  //   DocumentSnapshot doc =
  //       await usersRef.document('LV10wjAXZs4laxSUy91o').get();
  //   print(doc.data);
  //   // .then((value) => print(value.data));
  // }

  // getUsers() async {
  //   final QuerySnapshot snapshot =
  //       await usersRef.orderBy('postscount').getDocuments();
  //   setState(() {
  //     users = snapshot.documents;
  //   });

  // snapshot.documents.forEach((element) {
  //   print(element.data);
  //   print(element.documentID);
  //   print(element.exists);
  // });

  // usersRef.getDocuments().then((QuerySnapshot snapshot) {
  //   snapshot.documents.forEach((DocumentSnapshot doc) {
  //     print(doc.data);
  //     print(doc.documentID);
  //     print(doc.exists);
  //   });
  // });
  // }

  buildUserToFollow() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          usersRef.orderBy('timestamp', descending: true).limit(30).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }

        List<UserResult> userResults = [];
        snapshot.data?.docs.forEach((doc) {
          UserModel user = UserModel.fromDocument(doc);
          final bool isAuthUser = currentUser?.id == user.id;
          final bool isFollowingUser = followingList.contains(user.id);

          if (isAuthUser) {
            return;
          } else if (isFollowingUser) {
            return;
          } else {
            UserResult userResult = UserResult(user);
            userResults.add(userResult);
          }
        });
        return Container(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add,
                      color: Theme.of(context).primaryColor,
                      size: 30,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Text(
                      'Users to follow',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 30,
                      ),
                    )
                  ],
                ),
              ),
              Column(
                children: userResults,
              ),
            ],
          ),
        );
      },
    );
  }

  buildTimeline() {
    if (posts == null) {
      return circularProgress();
    } else if (posts!.isEmpty) {
      return buildUserToFollow();
    } else {
      return ListView(
        children: posts!,
      );
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, isAppTitle: true, titleText: ''),
      //   body: StreamBuilder<QuerySnapshot>(
      //     stream: usersRef.snapshots(),
      //     builder: (context, snapshot) {
      //       if (!snapshot.hasData) {
      //         return circularProgress();
      //       }
      //       final List<Text> children = snapshot.data.documents
      //           .map((doc) => Text(doc['username']))
      //           .toList();
      //       return Container(
      //         child: ListView(
      //           children: children,
      //         ),
      //       );
      //     },
      //   ),
      // );
      body: RefreshIndicator(
        onRefresh: () => getTimeline(),
        child: buildTimeline(),
      ),
    );
  }
}
