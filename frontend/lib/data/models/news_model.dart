class NewsModel {
  final String title;
  final String url;
  final String source;
  final String publishedAt;
  final String sentiment;

  NewsModel({
    required this.title,
    required this.url,
    required this.source,
    required this.publishedAt,
    required this.sentiment,
  });

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      title: json['title'] as String,
      url: json['url'] as String,
      source: json['source'] as String,
      publishedAt: json['published_at'] as String,
      sentiment: json['sentiment'] as String,
    );
  }
}
