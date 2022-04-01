import 'package:fluent_ui/fluent_ui.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_html/flutter_html.dart';
import 'package:hackernews/components/custom_text.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/services/theme_extensions.dart';

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

  Widget itemBuilder(CommentItem comment, ThemeData theme) {
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
                  customTextStyle: (_, __) =>
                      TextStyle(fontSize: 10, color: theme.textColor),
                ),
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return itemBuilder(widget.commentItem, theme);
  }
}
