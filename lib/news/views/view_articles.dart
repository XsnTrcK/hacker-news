import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/models/item.dart';
import 'package:hackernews/news/bloc/item_bloc.dart';
import 'package:hackernews/news/bloc/item_events.dart';
import 'package:hackernews/news/views/display_article.dart';
import 'package:hackernews/store/store.dart';

class ViewArticles extends StatelessWidget {
  final List<TitledItem> _articles;
  late PageController _pageController;

  ViewArticles(this._articles, {Key? key, initialIndex}) : super(key: key) {
    _pageController = PageController(initialPage: initialIndex ?? 0);
  }

  Widget _buildPage(ItemUpdater itemUpdater, TitledItem item) {
    return BlocProvider(
      create: (_) =>
          ItemBloc<TitledItem>(itemUpdater)..add(HasBeenReadEvent(item)),
      child: DisplayArticle(
        onPanUpdate: (details) {
          if (details.delta.dx > 0) {
            _pageController.previousPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          } else if (details.delta.dx < 0) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getNewsStore(),
      builder: (context, AsyncSnapshot<NewsStore> snapshot) {
        if (snapshot.hasData) {
          return PageView.builder(
            physics: const NeverScrollableScrollPhysics(),
            controller: _pageController,
            itemCount: _articles.length,
            itemBuilder: (context, index) {
              return _buildPage(snapshot.data!, _articles[index]);
            },
          );
        } else if (snapshot.hasError) {
          return const Center(child: Text('Unable to open selected article'));
        } else {
          return const Center(child: ProgressBar());
        }
      },
    );
  }
}
