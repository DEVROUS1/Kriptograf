import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/news_provider.dart';

class NewsTickerWidget extends ConsumerWidget {
  const NewsTickerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Son Haberler', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            newsAsync.when(
              data: (news) {
                if (news.isEmpty) return const Text('Haber bulunamadı.');
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: news.length > 5 ? 5 : news.length,
                  separatorBuilder: (context, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = news[index];
                    Color sentimentColor = Colors.grey;
                    if (item.sentiment == 'POZİTİF') sentimentColor = Colors.greenAccent;
                    if (item.sentiment == 'NEGATİF') sentimentColor = Colors.redAccent;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                      subtitle: Row(
                        children: [
                          Text(item.source, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: sentimentColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(item.sentiment, style: TextStyle(fontSize: 10, color: sentimentColor)),
                          ),
                        ],
                      ),
                      onTap: () {
                        // URL Launcher was removed to avoid pubspec dependency changes. User can view news on this widget.
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Haberler yüklenemedi.'),
            ),
          ],
        ),
      ),
    );
  }
}
