import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/ai_provider.dart';
import '../../data/models/signal_model.dart';
import 'common/shimmer_card.dart';

class SignalWidget extends ConsumerWidget {
  const SignalWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signalAsync = ref.watch(signalProvider);
    final anomalyAsync = ref.watch(anomalyProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: AppTheme.warning, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              const Text('SİNYAL MOTORU',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: Color(0xFF5a6080), letterSpacing: 0.8)),
            ]),
          ),
          signalAsync.when(
            data: (s) => _SignalBody(signal: s),
            loading: () => const ShimmerCard(height: 140),
            error: (_, __) => const SizedBox(height: 40),
          ),
          anomalyAsync.when(
            data: (d) {
              final list = (d['anomaliler'] as List).cast<Map<String, dynamic>>();
              if (list.isEmpty) return const SizedBox();
              return Column(children: list.map((a) => _AnomalyBanner(a: a)).toList());
            },
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
    );
  }
}

class _SignalBody extends StatelessWidget {
  const _SignalBody({required this.signal});
  final SignalModel signal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: signal.renkDegeri.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: signal.renkDegeri.withValues(alpha: 0.3)),
          ),
          child: Column(children: [
            Text(signal.yon,
                style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900,
                  color: signal.renkDegeri, letterSpacing: 1,
                )),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: signal.guc / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(signal.renkDegeri),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Sinyal Gücü: %${signal.guc}',
                    style: TextStyle(
                      fontSize: 10,
                      color: signal.renkDegeri.withValues(alpha: 0.7),
                    )),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        ...signal.nedenler.map((n) => Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Container(
                width: 4, height: 4,
                decoration: BoxDecoration(
                  color: signal.renkDegeri.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(child: Text(n,
                style: const TextStyle(fontSize: 11, color: Color(0xFFa0a4bc), height: 1.4))),
          ]),
        )),
      ]),
    );
  }
}

class _AnomalyBanner extends StatelessWidget {
  const _AnomalyBanner({required this.a});
  final Map<String, dynamic> a;

  @override
  Widget build(BuildContext context) {
    final kritik = a['siddet'] == 'KRİTİK';
    final color = kritik ? AppTheme.bearish : AppTheme.warning;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(kritik ? Icons.warning_rounded : Icons.info_outline, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(a['mesaj'] as String,
            style: TextStyle(fontSize: 11, color: color))),
      ]),
    );
  }
}
