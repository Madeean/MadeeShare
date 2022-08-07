import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:madee_share/pages/home.dart';
import 'package:madee_share/widgets/header.dart';
import 'package:madee_share/widgets/post.dart';
import 'package:madee_share/widgets/progress.dart';

class PostScreen extends StatelessWidget {
  final String userId;
  final String postId;

  PostScreen({required this.userId, required this.postId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: postRef.doc(userId).collection("userPosts").doc(postId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }

        Post post = Post.fromDocument(snapshot.data!);
        return Center(
          child: Scaffold(
            appBar: header(
              context,
              titleText: post.description,
              removeBackButton: false,
            ),
            body: ListView(
              children: [
                Container(
                  child: post,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
