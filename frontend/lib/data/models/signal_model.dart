import 'package:flutter/material.dart';

class SignalModel {
  final String yon;
  final int guc;
  final String renk;
  final double rsi;
  final double macd;
  final double hacimAnomali;
  final List<String> nedenler;
  final String sembol;

  const SignalModel({
    required this.yon,
    required this.guc,
    required this.renk,
    required this.rsi,
    required this.macd,
    required this.hacimAnomali,
    required this.nedenler,
    required this.sembol,
  });

  factory SignalModel.fromJson(Map<String, dynamic> j) => SignalModel(
        yon: j['yon'] as String,
        guc: (j['guc'] as num).toInt(),
        renk: j['renk'] as String,
        rsi: (j['rsi'] as num).toDouble(),
        macd: (j['macd'] as num).toDouble(),
        hacimAnomali: (j['hacim_anomali'] as num).toDouble(),
        nedenler: (j['nedenler'] as List).cast<String>(),
        sembol: j['sembol'] as String,
      );

  Color get renkDegeri => switch (renk) {
        'guclu_alis' => const Color(0xFF00D68F),
        'alis'       => const Color(0xFF00B37A),
        'satis'      => const Color(0xFFFF6B7A),
        'guclu_satis'=> const Color(0xFFFF4757),
        _            => const Color(0xFFFFD32A),
      };
}
