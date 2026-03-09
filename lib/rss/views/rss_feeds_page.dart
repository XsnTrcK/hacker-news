import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hackernews/rss/bloc/rss_feeds_bloc.dart';
import 'package:hackernews/rss/bloc/rss_feeds_events.dart';
import 'package:hackernews/rss/bloc/rss_feeds_state.dart';
import 'package:hackernews/rss/models/rss_feed.dart';
import 'package:hackernews/services/theme_extensions.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class RssFeedsPage extends StatefulWidget {
  const RssFeedsPage({super.key});

  @override
  State<RssFeedsPage> createState() => _RssFeedsPageState();
}

class _RssFeedsPageState extends State<RssFeedsPage> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    if (name.isEmpty || url.isEmpty) return;
    context
        .read<RssFeedsBloc>()
        .add(AddRssFeedEvent(RssFeedInfo(name: name, url: url)));
    _nameController.clear();
    _urlController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final typography = theme.dynamicTypography;

    return ScaffoldPage(
      padding: const EdgeInsets.symmetric(vertical: 0),
      content: BlocBuilder<RssFeedsBloc, RssFeedsState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 50, horizontal: 10),
                child: Text(
                  'RSS Feeds',
                  textAlign: TextAlign.start,
                  style: typography.display,
                ),
              ),
              Expanded(
                child: state.feeds.isEmpty
                    ? Center(
                        child: Text(
                          'No feeds added yet.',
                          style: typography.body,
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.feeds.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final feed = state.feeds[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Icon(MdiIcons.rss),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(feed.name,
                                          style: typography.bodyStrong),
                                      Text(
                                        feed.url,
                                        style: typography.caption,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(FluentIcons.delete),
                                  onPressed: () => context
                                      .read<RssFeedsBloc>()
                                      .add(RemoveRssFeedEvent(index)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const Divider(),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextBox(
                      controller: _nameController,
                      placeholder: 'Feed name',
                    ),
                    const SizedBox(height: 8),
                    TextBox(
                      controller: _urlController,
                      placeholder: 'Feed URL',
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => _submit(context),
                      child: const Text('Add Feed'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
