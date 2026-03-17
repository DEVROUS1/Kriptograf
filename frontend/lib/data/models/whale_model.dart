class WhaleTradeModel {
  final String id;
  final String zaman;
  final int timestamp;
  final double miktar;
  final double fiyat;
  final int usdDeger;
  final String yon; // "ALIŞ" veya "SATIŞ"
  final String sembol;

  const WhaleTradeModel({
    required this.id,
    required this.zaman,
    required this.timestamp,
    required this.miktar,
    required this.fiyat,
    required this.usdDeger,
    required this.yon,
    required this.sembol,
  });

  factory WhaleTradeModel.fromJson(Map<String, dynamic> j) => WhaleTradeModel(
        id: j['id'].toString(),
        zaman: j['zaman'] as String,
        timestamp: j['timestamp'] as int,
        miktar: (j['miktar'] as num).toDouble(),
        fiyat: (j['fiyat'] as num).toDouble(),
        usdDeger: (j['usd_deger'] as num).toInt(),
        yon: j['yon'] as String,
        sembol: j['sembol'] as String,
      );

  bool get alismi => yon == 'ALIŞ';

  String get usdFormatli {
    if (usdDeger >= 1000000) return '\$${(usdDeger / 1000000).toStringAsFixed(1)}M';
    return '\$${(usdDeger / 1000).toStringAsFixed(0)}K';
  }
}

class WhaleStatsModel {
  final int toplamBalikane;
  final int alisSayisi;
  final int satisSayisi;
  final int alisHacimUsd;
  final int satisHacimUsd;
  final String baski;
  final List<WhaleTradeModel> islemler;

  const WhaleStatsModel({
    required this.toplamBalikane,
    required this.alisSayisi,
    required this.satisSayisi,
    required this.alisHacimUsd,
    required this.satisHacimUsd,
    required this.baski,
    required this.islemler,
  });

  factory WhaleStatsModel.fromJson(Map<String, dynamic> j) => WhaleStatsModel(
        toplamBalikane: j['toplam_balikane'] as int,
        alisSayisi: j['alis_sayisi'] as int,
        satisSayisi: j['satis_sayisi'] as int,
        alisHacimUsd: (j['alis_hacim_usd'] as num).toInt(),
        satisHacimUsd: (j['satis_hacim_usd'] as num).toInt(),
        baski: j['baskı'] as String,
        islemler: (j['islemler'] as List)
            .map((e) => WhaleTradeModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  double get aliYuzde {
    final toplam = alisHacimUsd + satisHacimUsd;
    if (toplam == 0) return 50;
    return (alisHacimUsd / toplam) * 100;
  }
}
