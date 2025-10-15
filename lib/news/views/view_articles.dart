import 'package:fluent_ui/fluent_ui.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/news/views/display_article.dart';

class ViewArticles extends StatelessWidget {
  final List<TitledItem> _articles;
  final int? initialIndex;

  const ViewArticles(this._articles, {super.key, this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: PageController(initialPage: initialIndex ?? 0),
      itemCount: _articles.length,
      itemBuilder: (context, index) {
        return DisplayArticle(_articles[index]);
      },
    );
  }
}
