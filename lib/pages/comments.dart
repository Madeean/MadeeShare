import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:madee_share/pages/home.dart';
import 'package:madee_share/widgets/header.dart';
import 'package:madee_share/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeAgo;

class Comments extends StatefulWidget {
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  Comments(
      {required this.postId,
      required this.postOwnerId,
      required this.postMediaUrl});

  @override
  CommentsState createState() => CommentsState(
        postId: this.postId,
        postOwnerId: this.postOwnerId,
        postMediaUrl: this.postMediaUrl,
      );
}

class CommentsState extends State<Comments> {
  TextEditingController commentController = TextEditingController();
  final String postId;
  final String postOwnerId;
  final String postMediaUrl;

  CommentsState(
      {required this.postId,
      required this.postOwnerId,
      required this.postMediaUrl});

  buildComments() {
    return StreamBuilder<QuerySnapshot>(
      stream: commentsRef
          .doc(postId)
          .collection("comments")
          .orderBy("timestamp", descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }

        List<Comment> comments = [];
        snapshot.data?.docs.forEach((doc) {
          comments.add(Comment.fromDocument(doc));
        });
        return ListView(
          children: comments,
        );
      },
    );
  }

  addComent() {
    commentsRef.doc(postId).collection("comments").add({
      "username": currentUser?.username,
      "comment": commentController.text,
      "timestamp": timestamp,
      "avatarUrl": currentUser?.photoUrl,
      "userId": currentUser?.id,
    });
    bool isNotPostOwner = postOwnerId != currentUser?.id;
    if (isNotPostOwner) {
      activityFeedRef.doc(postOwnerId).collection("feedItems").add({
        "type": "comment",
        "commentData": commentController.text,
        "username": currentUser?.username,
        "userId": currentUser?.id,
        "userProfileImg": currentUser?.photoUrl,
        "postId": postId,
        "mediaUrl": postMediaUrl,
        "timestamp": timestamp,
      });
    }

    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Comments"),
      body: Column(
        children: [
          Expanded(
            child: buildComments(),
          ),
          Divider(),
          ListTile(
            title: TextFormField(
              controller: commentController,
              decoration: InputDecoration(
                labelText: "Write a comment",
              ),
            ),
            trailing: OutlinedButton(
              onPressed: addComent,
              style: OutlinedButton.styleFrom(
                side: BorderSide.none,
              ),
              child: Text('Post'),
            ),
          ),
        ],
      ),
    );
  }
}

class Comment extends StatelessWidget {
  final String username;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;

  Comment({
    required this.username,
    required this.userId,
    required this.avatarUrl,
    required this.comment,
    required this.timestamp,
  });

  factory Comment.fromDocument(DocumentSnapshot doc) {
    return Comment(
      username: doc['username'],
      userId: doc['userId'],
      avatarUrl: doc['avatarUrl'],
      comment: doc['comment'],
      timestamp: doc['timestamp'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ListTile(
        //   isThreeLine: true,
        //   title: Text("${username}"),
        //   leading: CircleAvatar(
        //     backgroundImage: CachedNetworkImageProvider(avatarUrl),
        //   ),
        //   subtitle: Text(timeAgo.format(timestamp.toDate())),
        // ),
        Container(
          padding: EdgeInsets.only(top: 20, left: 20, right: 20),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(avatarUrl),
                  ),
                  SizedBox(
                    width: 19,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(comment),
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          timeAgo.format(timestamp.toDate()),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
        ),
        Divider(),
      ],
    );
  }
}
