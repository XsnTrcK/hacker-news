import 'package:fluent_ui/fluent_ui.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_html/flutter_html.dart';
import 'package:hackernews/components/custom_text.dart';
import 'package:hackernews/models/item.dart';

class Comment extends StatefulWidget {
  final CommentItem commentItem;
  final bool isExpanded;

  const Comment(
    this.commentItem, {
    Key? key,
    this.isExpanded = true,
  }) : super(key: key);

  @override
  _CommentState createState() => _CommentState();
}

class _CommentState extends State<Comment> {
  late bool _isExpanded = false;

  @override
  void initState() {
    _isExpanded = widget.isExpanded;
    super.initState();
  }

  @override
  void didUpdateWidget(old) {
    super.didUpdateWidget(old);
    _isExpanded = widget.isExpanded;
  }

  Widget itemBuilder(CommentItem comment) {
    return Column(
      children: [
        CustomText(
          "${comment.createdBy} - ${comment.prettySinceMessage()}",
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          padding: const EdgeInsets.all(2),
        ),
        comment.isDead || !_isExpanded
            ? const SizedBox.shrink()
            : Visibility(
                visible: _isExpanded,
                child: Html(
                  data: comment.text,
                  customTextStyle: (_, __) => const TextStyle(fontSize: 10),
                ),
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return itemBuilder(widget.commentItem);
  }
}
