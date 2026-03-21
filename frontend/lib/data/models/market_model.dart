class MarketModel {
  final String symbol;
  final double price;
  final double changePercent;
  final double volume;
  final double high24h;
  final double low24h;

  MarketModel({
    required this.symbol,
    required this.price,
    required this.changePercent,
    this.volume = 0.0,
    this.high24h = 0.0,
    this.low24h = 0.0,
  });

  factory MarketModel.fromJson(Map<String, dynamic> json) {
    return MarketModel(
      symbol: (json['symbol'] ?? json['sembol'] ?? '').toString(),
      price: ((json['price'] ?? json['fiyat']) as num?)?.toDouble() ?? 0.0,
      changePercent: ((json['change_percent'] ?? json['degisim_yuzde']) as num?)?.toDouble() ?? 0.0,
      volume: ((json['volume'] ?? json['hacim_usdt']) as num?)?.toDouble() ?? 0.0,
      high24h: ((json['high_24h'] ?? json['yuksek_24h']) as num?)?.toDouble() ?? 0.0,
      low24h: ((json['low_24h'] ?? json['dusuk_24h']) as num?)?.toDouble() ?? 0.0,
    );
  }

  MarketModel copyWith({
    String? symbol,
    double? price,
    double? changePercent,
    double? volume,
    double? high24h,
    double? low24h,
  }) {
    return MarketModel(
      symbol: symbol ?? this.symbol,
      price: price ?? this.price,
      changePercent: changePercent ?? this.changePercent,
      volume: volume ?? this.volume,
      high24h: high24h ?? this.high24h,
      low24h: low24h ?? this.low24h,
    );
  }
}
