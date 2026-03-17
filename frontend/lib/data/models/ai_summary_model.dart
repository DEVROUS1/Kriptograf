class AiSummaryModel {
  final String ozet;
  final String sembol;
  final String olusturulma;
  final String model;

  const AiSummaryModel({
    required this.ozet,
    required this.sembol,
    required this.olusturulma,
    required this.model,
  });

  factory AiSummaryModel.fromJson(Map<String, dynamic> j) => AiSummaryModel(
        ozet: j['ozet'] as String,
        sembol: j['sembol'] as String,
        olusturulma: j['olusturulma'] as String,
        model: j['model'] as String? ?? 'llama-3.3-70b',
      );
}
