import 'package:flutter/material.dart';
import 'package:social_network_flutter/widgets/post.dart';

class PostTile extends StatelessWidget {
  final Post post;

  PostTile(this.post);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => print("showing post"),
      child: Image.network(post.mediaUrl),
    );
  }
}
