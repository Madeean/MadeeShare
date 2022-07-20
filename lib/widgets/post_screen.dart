import 'package:flutter/material.dart';
import 'package:social_network_flutter/pages/home.dart';
import 'package:social_network_flutter/widgets/header.dart';
import 'package:social_network_flutter/widgets/post.dart';
import 'package:social_network_flutter/widgets/progress.dart';

class PostScreen extends StatelessWidget {
  final String userId;
  final String postId;

  PostScreen({this.userId, this.postId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: postRef
          .document(userId)
          .collection("userPosts")
          .document(postId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }

        Post post = Post.fromDocument(snapshot.data);
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
