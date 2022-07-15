import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_network_flutter/widgets/header.dart';
import 'package:social_network_flutter/widgets/progress.dart';

final usersRef = Firestore.instance.collection('users');

class Timeline extends StatefulWidget {
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  // List<dynamic> users = [];

  @override
  void initState() {
    // TODO: implement initState
    // getUsers();

    // getUserById();
    // createUser();
    // updateUser();
    deleteUser();
    super.initState();
  }

  createUser() {
    usersRef.document("asdawdf").setData({
      "username": "zoro",
      "postscount": 5,
      "isAdmin": false,
    });
  }

  updateUser() async {
    final doc = await usersRef.document("6hu7Z9WVtxEQuU7noaLb").get();
    if (doc.exists) {
      doc.reference.updateData(
          {"username": "zoroax", "postscount": 5, "isAdmin": false});
    }
    // .updateData({"username": "zoroax", "postscount": 5, "isAdmin": false});
  }

  deleteUser() async {
    final doc = await usersRef.document("6hu7Z9WVtxEQuU7noaLb").get();

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

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, isAppTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          final List<Text> children = snapshot.data.documents
              .map((doc) => Text(doc['username']))
              .toList();
          return Container(
            child: ListView(
              children: children,
            ),
          );
        },
      ),
    );
  }
}
