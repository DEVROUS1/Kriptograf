import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../providers/ai_provider.dart';

class AiSummaryWidget extends ConsumerWidget {
  const AiSummaryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(aiSummaryProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Baslik(async: async),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: async.when(
              data: (s) => Text(
                s.ozet,
                style: const TextStyle(
                  color: Color(0xFFd0d4ee),
                  fontSize: 13,
                  height: 1.75,
                  fontStyle: FontStyle.italic,
                ),
              ),
              loading: () => const _Iskelet(),
              error: (_, __) => const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI özeti için Render.com\'a GROQ_API_KEY ekleyin.',
                      style: TextStyle(color: Color(0xFF8890b0), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Baslik extends StatelessWidget {
  const _Baslik({required this.async});
  final AsyncValue<dynamic> async;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: AppTheme.primary.withValues(alpha: 0.15))),
      ),
      child: Row(
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Text(
            'AI PİYASA ANALİSTİ — GROQ',
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w800,
              color: Color(0xFFa89fff), letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          async.whenOrNull(
            data: (s) => Text(
              s.olusturulma,
              style: const TextStyle(fontSize: 9, color: Color(0xFF5a6080)),
            ),
          ) ?? const SizedBox(),
        ],
      ),
    );
  }
}

class _Iskelet extends StatelessWidget {
  const _Iskelet();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Line(width: double.infinity),
        SizedBox(height: 6),
        _Line(width: double.infinity),
        SizedBox(height: 6),
        _Line(width: 220),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) => Container(
        width: width, height: 12,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(4),
        ),
      );
}
