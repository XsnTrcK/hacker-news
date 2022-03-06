final Uri _baseHackerNewsUri =
    Uri.parse("https://hacker-news.firebaseio.com/v0/");

final Uri topStoriesUri = _baseHackerNewsUri.resolve("./topstories.json");

Uri getItemUri(int id) => _baseHackerNewsUri.resolve("./item/$id.json");
