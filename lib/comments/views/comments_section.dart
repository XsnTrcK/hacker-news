import 'package:flutter/material.dart';
import 'package:hackernews/comments/views/comments_expansion.dart';

class CommentsSection extends StatelessWidget {
  final List<int> commentIds;
  const CommentsSection(this.commentIds, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        children: commentIds.map((id) => CommentsExpansion(id)).toList(),
      ),
    );
  }
}
