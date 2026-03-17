class PortfolioAsset {
  final String sembol;
  final double miktar;
  final double fiyatUsd;
  final double degerUsd;
  final double degerTl;

  const PortfolioAsset({
    required this.sembol,
    required this.miktar,
    required this.fiyatUsd,
    required this.degerUsd,
    required this.degerTl,
  });

  factory PortfolioAsset.fromJson(Map<String, dynamic> j) => PortfolioAsset(
        sembol: j['sembol'] as String,
        miktar: (j['miktar'] as num).toDouble(),
        fiyatUsd: (j['fiyat_usd'] as num).toDouble(),
        degerUsd: (j['deger_usd'] as num).toDouble(),
        degerTl: (j['deger_tl'] as num).toDouble(),
      );
}

class PortfolioModel {
  final List<PortfolioAsset> varliklar;
  final double toplamUsd;
  final double toplamTl;
  final double usdTry;

  const PortfolioModel({
    required this.varliklar,
    required this.toplamUsd,
    required this.toplamTl,
    required this.usdTry,
  });

  factory PortfolioModel.fromJson(Map<String, dynamic> j) => PortfolioModel(
        varliklar: (j['varliklar'] as List)
            .map((e) => PortfolioAsset.fromJson(e as Map<String, dynamic>))
            .toList(),
        toplamUsd: (j['toplam_usd'] as num).toDouble(),
        toplamTl: (j['toplam_tl'] as num).toDouble(),
        usdTry: (j['usd_try'] as num).toDouble(),
      );
}
