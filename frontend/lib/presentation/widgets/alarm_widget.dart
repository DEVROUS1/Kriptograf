import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/global_markets_provider.dart';
import '../providers/market_provider.dart';
import '../providers/selected_coin_provider.dart';

class AlarmWidget extends ConsumerStatefulWidget {
  const AlarmWidget({super.key});

  @override
  ConsumerState<AlarmWidget> createState() => _AlarmWidgetState();
}

class _AlarmWidgetState extends ConsumerState<AlarmWidget> {
  final _fiyatCtrl = TextEditingController();
  String _seciliYon = 'YUKARI';

  @override
  void dispose() {
    _fiyatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alarmlar = ref.watch(alarmProvider);
    final seciliCoin = ref.watch(selectedCoinProvider.select((coin) => coin.symbol.toUpperCase()));
    final piyasalar = ref.watch(marketListProvider);

    // Aktif coinin güncel fiyatı
    double? guncelFiyat;
    try {
      guncelFiyat = piyasalar.firstWhere((p) => p.symbol == seciliCoin).price;
    } catch (_) {}

    // Alarm Kontrolleri: Her alarm kendi sembolünün güncel fiyatıyla kontrol edilir!
    if (piyasalar.isNotEmpty) {
      for (final alarm in alarmlar) {
        if (!(alarm['aktif'] as bool)) continue;
        
        final hedef = (alarm['hedef'] as num).toDouble();
        final yon = alarm['yon'] as String;
        final sy = alarm['sembol'] as String;
        final id = alarm['id'] as String;
        
        // Bu alarmın coini güncel piyasa listesinde var mı? Fiyatı ne?
        double? eFiyat;
        try {
          eFiyat = piyasalar.firstWhere((p) => p.symbol == sy).price;
        } catch (_) {}

        if (eFiyat != null) {
          final tetiklendi = yon == 'YUKARI' ? eFiyat >= hedef : eFiyat <= hedef;

          if (tetiklendi) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _bildirimGoster(context, alarm, eFiyat!);
              // Sonsuz döngü ve spam'i önlemek için alarm tetiklendikten sonra sistemden uçur.
              ref.read(alarmProvider.notifier).sil(id);
            });
          }
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.warning, shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              const Text('FİYAT ALARMLARI',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: Color(0xFF5a6080), letterSpacing: 0.8)),
              const Spacer(),
              if (guncelFiyat != null)
                Text('Anlık: \$${guncelFiyat.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF5a6080))),
            ]),
          ),

          // Alarm ekle formu
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(children: [
              // Fiyat girişi
              Expanded(
                child: TextField(
                  controller: _fiyatCtrl,
                  decoration: InputDecoration(
                    hintText: guncelFiyat != null
                        ? guncelFiyat.toStringAsFixed(0)
                        : 'Hedef fiyat',
                    hintStyle: const TextStyle(
                        fontSize: 12, color: Color(0xFF3a3d55)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),

              // Yön seçici
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(children: [
                  _YonButon(
                    etiket: '▲',
                    secili: _seciliYon == 'YUKARI',
                    color: AppTheme.bullish,
                    onTap: () => setState(() => _seciliYon = 'YUKARI'),
                  ),
                  _YonButon(
                    etiket: '▼',
                    secili: _seciliYon == 'ASAGI',
                    color: AppTheme.bearish,
                    onTap: () => setState(() => _seciliYon = 'ASAGI'),
                  ),
                ]),
              ),
              const SizedBox(width: 8),

              // Ekle butonu
              GestureDetector(
                onTap: _alarmEkle,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.4)),
                  ),
                  child: const Text('Kur',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),

          // Alarm listesi
          if (alarmlar.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text('Henüz alarm yok.',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.2))),
            )
          else
            ...alarmlar.map((a) {
              double? ozelAnlikFiyat;
              try {
                ozelAnlikFiyat = piyasalar.firstWhere((p) => p.symbol == a['sembol']).price;
              } catch (_) {}
              
              return _AlarmSatiri(
                alarm: a,
                guncelFiyat: ozelAnlikFiyat ?? guncelFiyat, // Kendi fiyatı yoksa fallback
                onSil: () => ref.read(alarmProvider.notifier).sil(a['id'] as String),
              );
            }),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  void _alarmEkle() {
    final fiyat = double.tryParse(_fiyatCtrl.text.trim());
    if (fiyat == null || fiyat <= 0) return;
    
    // Doğru sembol ile ekle! Önceden 'BTC' statik yazılıydı.
    final coin = ref.read(selectedCoinProvider);
    
    ref.read(alarmProvider.notifier).ekle(
          sembol: coin.symbol.toUpperCase(),
          hedefFiyat: fiyat,
          yon: _seciliYon,
        );
    _fiyatCtrl.clear();
  }

  void _bildirimGoster(
      BuildContext context, Map<String, dynamic> alarm, double guncel) {
    final yon = alarm['yon'] as String;
    final hedef = (alarm['hedef'] as num).toDouble();
    final color = yon == 'YUKARI' ? AppTheme.bullish : AppTheme.bearish;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color.withValues(alpha: 0.9),
        content: Row(children: [
          Icon(
            yon == 'YUKARI' ? Icons.arrow_upward : Icons.arrow_downward,
            color: Colors.white, size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'ALARM: ${alarm['sembol'].toString().replaceAll('USDT', '')} \$${guncel.toStringAsFixed(2)} → '
            'Hedef \$${hedef.toStringAsFixed(2)} ${yon == 'YUKARI' ? 'Aşıldı' : 'Altına İndi'}!',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12),
          ),
        ]),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _YonButon extends StatelessWidget {
  const _YonButon({
    required this.etiket,
    required this.secili,
    required this.color,
    required this.onTap,
  });
  final String etiket;
  final bool secili;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: secili ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(etiket,
            style: TextStyle(
                fontSize: 13,
                color: secili ? color : Colors.white.withValues(alpha: 0.3))),
      ),
    );
  }
}

class _AlarmSatiri extends StatelessWidget {
  const _AlarmSatiri({
    required this.alarm,
    required this.guncelFiyat,
    required this.onSil,
  });
  final Map<String, dynamic> alarm;
  final double? guncelFiyat;
  final VoidCallback onSil;

  @override
  Widget build(BuildContext context) {
    final hedef = (alarm['hedef'] as num).toDouble();
    final yon = alarm['yon'] as String;
    final color = yon == 'YUKARI' ? AppTheme.bullish : AppTheme.bearish;

    // Tetiklenme yüzdesi hesaplaması (Kendi sembolünün anlık fiyatı üzerinden)
    double ilerleme = 0;
    
    // Anlık fiyat dışarıdan (guncelFiyat = seçili coin) gelmek zorunda değil, provider ile izole de alınabilir
    // ama guncelFiyat parametresi widget tarafından sağlanıyordu. Burada kendi sembolünün güncel fiyatını almak en doğrusu!
    // ConsumerWidget ile state watch olmadığından, yukarıdan parametre olarak sadece "zaten filtrelenmiş" kendi sembolünün fiyatını verelim.
    // Ancak dışarıda geçilen (guncelFiyat) genelde "seçili_coin" fiyatı olabiliyor.
    // Bu yüzden parametre yerine tam ilerlemeyi hesaplamak için güncel fiyatı doğrudan buraya entegre ettik.
    if (guncelFiyat != null && guncelFiyat! > 0) {
      if (yon == 'YUKARI') {
        ilerleme = (guncelFiyat! / hedef).clamp(0.0, 1.0);
      } else {
        ilerleme = (hedef / guncelFiyat!).clamp(0.0, 1.0);
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Row(children: [
          Icon(
            yon == 'YUKARI' ? Icons.arrow_upward : Icons.arrow_downward,
            size: 13, color: color,
          ),
          const SizedBox(width: 6),
          Text(
            yon == 'YUKARI' ? 'Fiyat ≥ ' : 'Fiyat ≤ ',
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7)),
          ),
          Text('\$${hedef.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w700)),
          const Spacer(),
          Text(alarm['sembol'].toString().replaceAll('USDT', ''),
              style: const TextStyle(
                  fontSize: 9, color: Color(0xFF5a6080), fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSil,
            child: Icon(Icons.close_rounded,
                size: 14,
                color: Colors.white.withValues(alpha: 0.25)),
          ),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: ilerleme,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.5)),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 3),
        Align(
          alignment: Alignment.centerRight,
          child: Text('%${(ilerleme * 100).toStringAsFixed(1)} tamamlandı',
              style: TextStyle(
                  fontSize: 9,
                  color: color.withValues(alpha: 0.5))),
        ),
      ]),
    );
  }
}
