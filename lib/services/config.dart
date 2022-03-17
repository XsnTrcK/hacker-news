final Uri _baseHackerNewsUri =
    Uri.parse("https://hacker-news.firebaseio.com/v0/");

final Uri topStoriesUri = _baseHackerNewsUri.resolve("./topstories.json");
final Uri newStoriesUri = _baseHackerNewsUri.resolve("./newstories.json");
final Uri bestStoriesUri = _baseHackerNewsUri.resolve("./beststories.json");
final Uri askStoriesUri = _baseHackerNewsUri.resolve("./askstories.json");
final Uri showStoriesUri = _baseHackerNewsUri.resolve("./showstories.json");
final Uri jobStoriesUri = _baseHackerNewsUri.resolve("./jobstories.json");

Uri getItemUri(int id) => _baseHackerNewsUri.resolve("./item/$id.json");
