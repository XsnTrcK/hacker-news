import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hackernews/components/custom_text.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/services/theme_extensions.dart';
import 'package:hackernews/services/link_handler.dart';

class Comment extends StatefulWidget {
  final CommentItem commentItem;
  final bool isExpanded;

  const Comment(
    this.commentItem, {
    super.key,
    this.isExpanded = true,
  });

  @override
  State<Comment> createState() => _CommentState();
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

  Widget itemBuilder(CommentItem comment, FluentThemeData theme) {
    final typography = theme.dynamicTypography;
    return Column(
      children: [
        CustomText(
          "${comment.createdBy} - ${comment.prettySinceMessage()}",
          style: typography.caption!.merge(
            const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          padding: const EdgeInsets.all(2),
        ),
        comment.isDead || comment.isDeleted || !_isExpanded
            ? const SizedBox.shrink()
            : Visibility(
                visible: _isExpanded,
                child: Html(
                  data: '<body>${comment.text}</body>',
                  onLinkTap: (url, _, __) => handleLinkTap(context, url),
                  style: {
                    "body": Style(
                      fontSize: FontSize(typography.caption!.fontSize!),
                      color: theme.textColor,
                      padding: HtmlPaddings.zero,
                      margin: Margins.symmetric(horizontal: 2),
                    )
                  },
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
