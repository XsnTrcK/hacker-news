class RssFeedInfo {
  final String name;
  final String url;

  const RssFeedInfo({required this.name, required this.url});

  Map<String, dynamic> toMap() => {'name': name, 'url': url};

  factory RssFeedInfo.fromMap(Map<String, dynamic> map) =>
      RssFeedInfo(name: map['name'] as String, url: map['url'] as String);
}

const allFeedsInfo = RssFeedInfo(name: 'All Feeds', url: '');
