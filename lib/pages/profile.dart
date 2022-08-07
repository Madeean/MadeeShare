import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:madee_share/models/user_model.dart';
import 'package:madee_share/pages/edit_profile.dart';
import 'package:madee_share/pages/home.dart';
import 'package:madee_share/pages/upload.dart';
import 'package:madee_share/widgets/header.dart';
import 'package:madee_share/widgets/post.dart';
import 'package:madee_share/widgets/post_tile.dart';
import 'package:madee_share/widgets/progress.dart';

class Profile extends StatefulWidget {
  final String profileId;

  Profile({required this.profileId});
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isFollowing = false;
  final String currentUserId = currentUser!.id;
  bool isloading = false;
  int postCount = 0;
  int followersCount = 0;
  int followingCount = 0;
  List<Post> posts = [];
  String postOrientation = "grid";

  @override
  void initState() {
    super.initState();
    getProfilePost();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .doc(widget.profileId)
        .collection("userFollowing")
        .get();
    setState(() {
      followingCount = snapshot.docs.length;
    });
  }

  getFollowers() async {
    QuerySnapshot snapshot = await followersRef
        .doc(widget.profileId)
        .collection("userFollowers")
        .get();
    setState(() {
      followersCount = snapshot.docs.length;
    });
  }

  checkIfFollowing() async {
    DocumentSnapshot doc = await followersRef
        .doc(widget.profileId)
        .collection("userFollowers")
        .doc(currentUserId)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  getProfilePost() async {
    setState(() {
      isloading = true;
    });
    QuerySnapshot snapshot = await postRef
        .doc(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      isloading = false;
      postCount = snapshot.docs.length;
      posts = snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: TextStyle(
                color: Colors.grey, fontSize: 15, fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }

  editProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfile(currentUserId: currentUserId),
      ),
    );
  }

  Widget buildButton({required String text, required VoidCallback function}) {
    return Container(
      padding: EdgeInsets.only(top: 2),
      child: MaterialButton(
        onPressed: function,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          height: 27,
          child: Text(
            text,
            style: TextStyle(
              color: isFollowing ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFollowing ? Colors.white : Colors.blue,
            border: Border.all(
              color: isFollowing ? Colors.grey : Colors.blue,
            ),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }

  handleUnfollowUser() {
    setState(() {
      isFollowing = false;
    });

    followersRef
        .doc(widget.profileId)
        .collection("userFollowers")
        .doc(currentUserId)
        .get()
        .then((value) {
      if (value.exists) {
        value.reference.delete();
      }
    });

    followingRef
        .doc(currentUserId)
        .collection("userFollowing")
        .doc(widget.profileId)
        .get()
        .then((value) {
      if (value.exists) {
        value.reference.delete();
      }
    });

    activityFeedRef
        .doc(widget.profileId)
        .collection("feedItems")
        .doc(currentUserId)
        .get()
        .then((value) {
      if (value.exists) {
        value.reference.delete();
      }
    });
  }

  handleFollowUser() {
    setState(() {
      isFollowing = true;
    });

    followersRef
        .doc(widget.profileId)
        .collection("userFollowers")
        .doc(currentUserId)
        .set({});

    followingRef
        .doc(currentUserId)
        .collection("userFollowing")
        .doc(widget.profileId)
        .set({});
    activityFeedRef
        .doc(widget.profileId)
        .collection("feedItems")
        .doc(currentUserId)
        .set({
      "type": "follow",
      "ownerId": widget.profileId,
      "username": currentUser?.username,
      "userId": currentUserId,
      "userProfileImg": currentUser?.photoUrl,
      "timestamp": timestamp,
    });
  }

  buildProfileButton() {
    bool isProfileOwner = currentUserId == widget.profileId;
    if (isProfileOwner) {
      return buildButton(
        text: "Editing Profile",
        function: editProfile,
      );
    } else if (isFollowing) {
      return buildButton(
        text: "Unfollow",
        function: handleUnfollowUser,
      );
    } else if (!isFollowing) {
      return buildButton(
        text: "Follow",
        function: handleFollowUser,
      );
    }
  }

  buildProfileHeader() {
    return FutureBuilder<DocumentSnapshot>(
      future: usersRef.doc(widget.profileId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }

        UserModel user = UserModel.fromDocument(snapshot.data!);
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl,
                        errorListener: () => ClipRRect(
                              child: Icon(Icons.account_box),
                            )),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildCountColumn("posts", postCount),
                            buildCountColumn("followers", followersCount),
                            buildCountColumn("following", followingCount),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildProfileButton(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  user.username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  user.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  user.bio,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  buildProfilePost() {
    if (isloading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/images/no_content.svg',
              height: 260,
            ),
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text(
                'No posts',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 40,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } else if (postOrientation == "grid") {
      List<GridTile> grid = [];
      posts.forEach((post) {
        grid.add(GridTile(
          child: PostTile(post),
        ));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1,
        mainAxisSpacing: 1.6,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: grid,
      );
      //
    } else if (postOrientation == "list") {
      return Column(
        children: posts,
      );
    }
  }

  buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              postOrientation = "grid";
            });
          },
          icon: Icon(
            Icons.grid_on,
            color: postOrientation == "grid"
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() {
              postOrientation = "list";
            });
          },
          icon: Icon(
            Icons.list,
            color: postOrientation == "list"
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, titleText: "Profile"),
      body: ListView(
        children: [
          buildProfileHeader(),
          Divider(),
          buildTogglePostOrientation(),
          Divider(
            height: 0,
          ),
          buildProfilePost(),
        ],
      ),
    );
  }
}
