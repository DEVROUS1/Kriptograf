import 'package:intl/intl.dart';

class Formatters {
  /// Kripto paraların dinamik fiyat formatı. 
  /// Büyük coinler (BTC) için 2 ondalık ($70,000.50), 
  /// küçük coinler (PEPE) için 6 veya daha fazla ondalık ($0.000004) gösterir.
  static String formatKriptoFiyat(double fiyat) {
    if (fiyat == 0) return '0.00';
    final absFiyat = fiyat.abs();

    if (absFiyat >= 1000) {
      final f = NumberFormat('#,##0.00', 'en_US');
      return f.format(fiyat);
    } else if (absFiyat >= 1) {
      return fiyat.toStringAsFixed(2);
    } else if (absFiyat >= 0.01) {
      return fiyat.toStringAsFixed(4);
    } else if (absFiyat >= 0.0001) {
      return fiyat.toStringAsFixed(6);
    } else {
      return fiyat.toStringAsFixed(8);
    }
  }

  /// TL ve USD formatları binlik ayracı ile döndürür.
  static String formatPara(double miktar, {bool tl = false}) {
    final f = NumberFormat('#,##0.00', 'en_US');
    if (tl) {
      return '₺${f.format(miktar)}';
    }
    return '\$${f.format(miktar)}';
  }

  /// Kripto hacimleri (12.5M, 1.2B) vb kısa formatta döndürür.
  static String formatHacim(double hacim) {
    if (hacim >= 1e9) return '\$${(hacim / 1e9).toStringAsFixed(2)}B';
    if (hacim >= 1e6) return '\$${(hacim / 1e6).toStringAsFixed(2)}M';
    if (hacim >= 1e3) return '\$${(hacim / 1e3).toStringAsFixed(0)}K';
    return '\$${hacim.toStringAsFixed(0)}';
  }
}
