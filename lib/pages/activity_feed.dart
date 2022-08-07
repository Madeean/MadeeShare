import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:madee_share/pages/home.dart';
import 'package:madee_share/pages/profile.dart';
import 'package:madee_share/widgets/header.dart';
import 'package:madee_share/widgets/post_screen.dart';
import 'package:madee_share/widgets/progress.dart';
import 'package:timeago/timeago.dart' as timeAgo;

class ActivityFeed extends StatefulWidget {
  @override
  _ActivityFeedState createState() => _ActivityFeedState();
}

class _ActivityFeedState extends State<ActivityFeed> {
  // getActivityFeed() async {
  //   QuerySnapshot snapshot = await activityFeedRef
  //       .doc(currentUser?.id)
  //       .collection("feedItems")
  //       .orderBy('timestamp', descending: true)
  //       .limit(50)
  //       .get();
  //   // snapshot.documents.forEach((element) {
  //   //   print('activity feed item: ${element.data}');
  //   // });
  //   List<ActivityFeedItem> feedItems = [];
  //   snapshot.docs.forEach((element) {
  //     feedItems.add(ActivityFeedItem.fromDocument(element));
  //   });
  //   return feedItems;
  // }
  Future<List<ActivityFeedItem>> getActivityFeed() async {
    try {
      QuerySnapshot snapshot = await activityFeedRef
          .doc(currentUser!.id)
          .collection('feedItems')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      List<ActivityFeedItem> feedItems = [];
      snapshot.docs.forEach((doc) {
        feedItems.add(ActivityFeedItem.fromDocument(doc));
        print('Activity Feed Item: ${doc.data}');
      });

      return feedItems;
    } catch (error) {
      print(error);
      return <ActivityFeedItem>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange,
      appBar: header(context, titleText: "Activity Feed"),
      body: Container(
        child: FutureBuilder<List<ActivityFeedItem>>(
          future: getActivityFeed(),
          builder: (BuildContextcontext,
              AsyncSnapshot<List<ActivityFeedItem>> snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("You have an error in loading data"));
            }
            if (snapshot.hasData) {
              return ListView(
                children: snapshot.data!,
              );
            }
            return circularProgress();
          },
        ),
      ),
    );
  }
}

Widget? MediaPreview;
String? activityItemText;

class ActivityFeedItem extends StatelessWidget {
  final String username;
  final String userId;
  final String type;
  final String mediaUrl;
  final String postId;
  final String userProfileImg;
  final String commentData;
  final Timestamp timestamp;

  ActivityFeedItem({
    required this.username,
    required this.userId,
    required this.type,
    required this.mediaUrl,
    required this.postId,
    required this.userProfileImg,
    required this.commentData,
    required this.timestamp,
  });

  factory ActivityFeedItem.fromDocument(doc) {
    return ActivityFeedItem(
      username: doc['username'],
      userId: doc['userId'],
      type: doc['type'],
      mediaUrl: doc['mediaUrl'],
      postId: doc['postId'],
      userProfileImg: doc['userProfileImg'],
      commentData: doc['commentData'],
      timestamp: doc['timestamp'],
    );
  }

  showPost(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(
          postId: postId,
          userId: userId,
        ),
      ),
    );
  }

  configureMediaPreview(context) {
    if (type == "like" || type == "comment") {
      MediaPreview = GestureDetector(
        onTap: () => showPost(
          context,
        ),
        child: Container(
          height: 50,
          width: 50,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: CachedNetworkImageProvider(mediaUrl),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      MediaPreview = Text('');
    }

    if (type == "like") {
      activityItemText = "liked your post";
    } else if (type == "follow") {
      activityItemText = "following you";
    } else if (type == "comment") {
      activityItemText = "replied: $commentData";
    } else {
      activityItemText = "error unkown type $type";
    }
  }

  @override
  Widget build(BuildContext context) {
    configureMediaPreview(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 2),
      child: Container(
        color: Colors.white54,
        child: ListTile(
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: userId),
            child: RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(
                    text: username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: ' $activityItemText',
                  ),
                ],
              ),
            ),
          ),
          leading: CircleAvatar(
            backgroundImage: NetworkImage(userProfileImg),
          ),
          subtitle: Text(
            timeAgo.format(timestamp.toDate()),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: MediaPreview,
        ),
      ),
    );
  }
}

showProfile(BuildContext context, {required String profileId}) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Profile(
        profileId: profileId,
      ),
    ),
  );
}
