class PortfolioAsset {
  final String? id;
  final String sembol;
  final double miktar;
  final double fiyatUsd;
  final double degerUsd;
  final double degerTl;
  final double? alisFiyati;
  final double? karZararUsd;
  final double? karZararYuzde;

  const PortfolioAsset({
    this.id,
    required this.sembol,
    required this.miktar,
    required this.fiyatUsd,
    required this.degerUsd,
    required this.degerTl,
    this.alisFiyati,
    this.karZararUsd,
    this.karZararYuzde,
  });

  factory PortfolioAsset.fromJson(Map<String, dynamic> j) => PortfolioAsset(
        id: j['id'] as String?,
        sembol: j['sembol'] as String,
        miktar: (j['miktar'] as num).toDouble(),
        fiyatUsd: (j['fiyat_usd'] as num).toDouble(),
        degerUsd: (j['deger_usd'] as num).toDouble(),
        degerTl: (j['deger_tl'] as num).toDouble(),
        alisFiyati: j['alis_fiyati'] != null
            ? (j['alis_fiyati'] as num).toDouble()
            : null,
        karZararUsd: j['kar_zarar_usd'] != null
            ? (j['kar_zarar_usd'] as num).toDouble()
            : null,
        karZararYuzde: j['kar_zarar_yuzde'] != null
            ? (j['kar_zarar_yuzde'] as num).toDouble()
            : null,
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
