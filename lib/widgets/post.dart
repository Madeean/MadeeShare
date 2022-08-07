import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:madee_share/models/user_model.dart';
import 'package:madee_share/pages/activity_feed.dart';
import 'package:madee_share/pages/comments.dart';
import 'package:madee_share/pages/home.dart';
import 'package:madee_share/widgets/custom_image.dart';
import 'package:madee_share/widgets/progress.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  Post({
    required this.postId,
    required this.ownerId,
    required this.username,
    required this.location,
    required this.description,
    required this.mediaUrl,
    required this.likes,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      location: doc['location'],
      description: doc['description'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
    );
  }

  int getLikeCount(likes) {
    if (likes == null) {
      return 0;
    }
    int count = 0;
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        username: this.username,
        location: this.location,
        description: this.description,
        mediaUrl: this.mediaUrl,
        likes: this.likes,
        likeCount: getLikeCount(this.likes),
      );
}

class _PostState extends State<Post> {
  final String? currentUserId = currentUser?.id;

  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  int likeCount;
  Map likes;
  late bool _isLiked;
  bool showHeart = false;

  _PostState({
    required this.postId,
    required this.ownerId,
    required this.username,
    required this.location,
    required this.description,
    required this.mediaUrl,
    required this.likes,
    required this.likeCount,
  });

  @override
  void initState() {
    super.initState();
  }

  buildPostHeader() {
    return FutureBuilder<DocumentSnapshot>(
      future: usersRef.doc(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        UserModel user = UserModel.fromDocument(snapshot.data!);
        bool isPostOwner = currentUserId == ownerId;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => showProfile(
              context,
              profileId: user.id,
            ),
            child: Text(
              user.username,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(location),
          trailing: isPostOwner
              ? IconButton(
                  onPressed: () => handleDeletePost(context),
                  icon: Icon(Icons.more_vert),
                )
              : Text(''),
        );
      },
    );
  }

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 5,
            title: Text('remove this post?'),
            children: [
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  deletePost();
                },
                child: Text(
                  'delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
            ],
          );
        });
  }

  deletePost() async {
    postRef
        .doc(ownerId)
        .collection("userPosts")
        .doc(postId)
        .get()
        .then((value) {
      if (value.exists) {
        value.reference.delete();
      }
    });

    storageRef.child("post_$postId.jpg").delete();

    QuerySnapshot activityFeedSnapshot = await activityFeedRef
        .doc(ownerId)
        .collection("feedItems")
        .where("postId", isEqualTo: postId)
        .get();

    activityFeedSnapshot.docs.forEach((element) {
      if (element.exists) {
        element.reference.delete();
      }
    });

    QuerySnapshot commentsSnapshot =
        await commentsRef.doc(postId).collection("comments").get();
    commentsSnapshot.docs.forEach((element) {
      if (element.exists) {
        element.reference.delete();
      }
    });
  }

  handleLikePost() {
    bool _isLiked = likes[currentUserId] == true;

    if (_isLiked) {
      postRef
          .doc(ownerId)
          .collection('userPosts')
          .doc(postId)
          .update({'likes.$currentUserId': false});
      removeLikeFromActivityFeed();
      setState(() {
        likeCount -= 1;
        _isLiked = false;
        likes[currentUserId] = false;
      });
    } else if (!_isLiked) {
      postRef
          .doc(ownerId)
          .collection('userPosts')
          .doc(postId)
          .update({'likes.$currentUserId': true});
      addLikeToActivityFeed();
      setState(() {
        likeCount += 1;
        _isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(
        Duration(milliseconds: 500),
        () {
          setState(() {
            showHeart = false;
          });
        },
      );
    }
  }

  removeLikeFromActivityFeed() {
    // add a notification

    bool isNotPostOwner = currentUserId != ownerId;

    if (isNotPostOwner) {
      activityFeedRef
          .doc(ownerId)
          .collection("feedItems")
          .doc(postId)
          .get()
          .then((doc) {
        if (doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }

  addLikeToActivityFeed() {
    bool isNotPostOwner = currentUserId != ownerId;
    if (isNotPostOwner) {
      activityFeedRef.doc(ownerId).collection("feedItems").doc(postId).set({
        "type": "like",
        "username": currentUser?.username,
        "userId": currentUser?.id,
        "userProfileImg": currentUser?.photoUrl,
        "postId": postId,
        "mediaUrl": mediaUrl,
        "timestamp": timestamp,
      });
    }
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.network(mediaUrl),
          // showHeart
          //     ? Animator(
          //         duration: Duration(microseconds: 300),
          //         tween: Tween(begin: 0.8, end: 1.4),
          //         curve: Curves.elasticOut,
          //         cycles: 0,
          //         builder: (anim) => Transform.scale(
          //           scale: anim.value,
          //           child: Icon(
          //             Icons.favorite,
          //             size: 80,
          //             color: Colors.red,
          //           ),
          //         ),
          //       )
          //     : Text(""),
          showHeart
              ? Icon(
                  Icons.favorite,
                  size: 80,
                  color: Colors.red,
                )
              : Text(""),
        ],
      ),
    );
  }

  buildPostFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 40, left: 20),
            ),
            GestureDetector(
              onTap: handleLikePost,
              child: Icon(
                _isLiked ? Icons.favorite : Icons.favorite_border,
                size: 28,
                color: Colors.pink,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 20),
            ),
            GestureDetector(
              onTap: () => showComments(
                context,
                postId: postId,
                ownerId: ownerId,
                mediaUrl: mediaUrl,
              ),
              child: Icon(
                Icons.chat,
                size: 28,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                "$likeCount likes",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(left: 20),
              child: Text(
                "$username ",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Text(description),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _isLiked = (likes[currentUserId] == true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
      ],
    );
  }
}

showComments(
  BuildContext context, {
  required String postId,
  required String ownerId,
  required String mediaUrl,
}) {
  Navigator.push(context, MaterialPageRoute(builder: (context) {
    return Comments(
      postId: postId,
      postOwnerId: ownerId,
      postMediaUrl: mediaUrl,
    );
  }));
}
