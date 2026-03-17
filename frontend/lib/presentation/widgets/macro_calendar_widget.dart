import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MacroCalendarWidget extends StatefulWidget {
  const MacroCalendarWidget({super.key});

  @override
  State<MacroCalendarWidget> createState() => _MacroCalendarWidgetState();
}

class _MacroCalendarWidgetState extends State<MacroCalendarWidget> {
  late Timer _timer;
  Duration _remaining = const Duration(hours: 48, minutes: 22, seconds: 15);
  final List<Map<String, dynamic>> _events = [
    {'title': 'ABD TÜFE (CPI)', 'time': 'Yarın, 15:30', 'isim': 'Enflasyon Verisi', 'etki': 'YÜKSEK'},
    {'title': 'FED Faiz Kararı', 'time': 'Çarşamba, 21:00', 'isim': 'Faiz Oranı / FOMC', 'etki': 'KRİTİK'},
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remaining = _remaining - const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: Colors.orangeAccent, shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              const Text('MAKRO EKONOMİ \n(Wall Street)',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                      color: Color(0xFF5a6080), letterSpacing: 0.8)),
              const Spacer(),
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                 decoration: BoxDecoration(
                   color: Colors.orangeAccent.withValues(alpha: 0.15),
                   borderRadius: BorderRadius.circular(4),
                 ),
                 child: Row(
                   children: [
                     const Icon(Icons.timer_outlined, color: Colors.orangeAccent, size: 10),
                     const SizedBox(width: 4),
                     Text('${_remaining.inHours}:${(_remaining.inMinutes % 60).toString().padLeft(2, '0')}:${(_remaining.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 10, color: Colors.orangeAccent, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
                   ],
                 )
              ),
            ]),
          ),
          
          ..._events.map((e) => _EventRow(event: e)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final Map<String, dynamic> event;
  const _EventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final etki = event['etki'] as String;
    final rnk = etki == 'KRİTİK' ? AppTheme.bearish : Colors.orangeAccent;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
         color: Colors.white.withValues(alpha: 0.02),
         borderRadius: BorderRadius.circular(8),
         border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             children: [
               Icon(Icons.event_note_rounded, color: rnk, size: 14),
               const SizedBox(width: 6),
               Text(event['title'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
               const Spacer(),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                 decoration: BoxDecoration(
                   color: rnk,
                   borderRadius: BorderRadius.circular(3),
                 ),
                 child: Text(etki, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
               )
             ]
           ),
           const SizedBox(height: 6),
           Row(
             children: [
                Text(event['isim'], style: const TextStyle(color: Color(0xFF8890b0), fontSize: 11)),
                const Spacer(),
                Text(event['time'], style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
             ],
           )
        ],
      ),
    );
  }
}
