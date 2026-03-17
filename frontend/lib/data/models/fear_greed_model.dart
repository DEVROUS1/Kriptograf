class FearGreedModel {
  final int value;
  final String classification;
  final String timestamp;

  FearGreedModel({
    required this.value,
    required this.classification,
    required this.timestamp,
  });

  factory FearGreedModel.fromJson(Map<String, dynamic> json) {
    return FearGreedModel(
      value: json['value'] as int,
      classification: json['classification'] as String,
      timestamp: json['timestamp'] as String,
    );
  }
}
