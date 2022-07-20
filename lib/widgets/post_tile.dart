import 'package:flutter/material.dart';
import 'package:social_network_flutter/widgets/post.dart';
import 'package:social_network_flutter/widgets/post_screen.dart';

class PostTile extends StatelessWidget {
  final Post post;

  PostTile(this.post);

  showPost(context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostScreen(
          postId: post.postId,
          userId: post.ownerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showPost(context),
      child: Image.network(post.mediaUrl),
    );
  }
}
