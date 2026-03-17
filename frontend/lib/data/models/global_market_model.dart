class MarketItemModel {
  final String isim;
  final double? fiyat;
  final double? degisim;

  const MarketItemModel({
    required this.isim,
    this.fiyat,
    this.degisim,
  });

  factory MarketItemModel.fromJson(String isim, Map<String, dynamic>? veri) {
    if (veri == null) return MarketItemModel(isim: isim);
    return MarketItemModel(
      isim: isim,
      fiyat: (veri['fiyat'] as num?)?.toDouble(),
      degisim: (veri['degisim'] as num?)?.toDouble(),
    );
  }

  bool get pozitif => (degisim ?? 0) >= 0;

  String get degisimStr {
    if (degisim == null) return '-';
    final s = degisim! >= 0 ? '+' : '';
    return '$s${degisim!.toStringAsFixed(2)}%';
  }

  String get fiyatStr {
    if (fiyat == null) return '-';
    if (fiyat! >= 10000) return fiyat!.toStringAsFixed(0);
    if (fiyat! >= 100) return fiyat!.toStringAsFixed(2);
    return fiyat!.toStringAsFixed(4);
  }
}

class GlobalMarketsModel {
  final Map<String, MarketItemModel> kuresel;
  final Map<String, dynamic> turkiye;
  final Map<String, double?> kriptoTl;
  final Map<String, dynamic> korkuAcgozluluk;
  final String guncelleme;

  const GlobalMarketsModel({
    required this.kuresel,
    required this.turkiye,
    required this.kriptoTl,
    required this.korkuAcgozluluk,
    required this.guncelleme,
  });

  factory GlobalMarketsModel.fromJson(Map<String, dynamic> j) {
    final kureselRaw = j['kuresel'] as Map<String, dynamic>;
    final kuresel = kureselRaw.map((k, v) {
      final veri = (v as Map<String, dynamic>)['veri'] as Map<String, dynamic>?;
      final isim = v['isim'] as String;
      return MapEntry(k, MarketItemModel.fromJson(isim, veri));
    });

    return GlobalMarketsModel(
      kuresel: kuresel,
      turkiye: j['turkiye'] as Map<String, dynamic>,
      kriptoTl: {
        'btc_try': (j['kripto_tl']['btc_try'] as num?)?.toDouble(),
        'eth_try': (j['kripto_tl']['eth_try'] as num?)?.toDouble(),
      },
      korkuAcgozluluk: j['korku_acgozluluk'] as Map<String, dynamic>,
      guncelleme: j['guncelleme'] as String,
    );
  }
}
