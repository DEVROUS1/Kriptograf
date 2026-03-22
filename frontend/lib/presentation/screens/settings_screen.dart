import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';

final notificationsProvider = StateProvider<bool>((ref) => true);
final darkModeProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifOn = ref.watch(notificationsProvider);
    final darkOn = ref.watch(darkModeProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Ayarlar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('HESAP'),
          _buildSettingsTile(context, icon: Icons.person_rounded, title: 'Profil Bilgileri', subtitle: 'Kriptograf PRO Üyesi'),
          _buildSettingsTile(context, icon: Icons.security_rounded, title: 'Güvenlik & 2FA', subtitle: 'Aktif'),
          
          const SizedBox(height: 24),
          _buildSectionHeader('API ENTEGRASYONU'),
          _buildSettingsTile(context, icon: Icons.key_rounded, title: 'Binance API Key', subtitle: 'Bağlandı'),
          _buildSettingsTile(context, icon: Icons.webhook_rounded, title: 'Webhook URL', subtitle: 'Ayarlanmadı'),

          const SizedBox(height: 24),
          _buildSectionHeader('UYGULAMA'),
          _buildSwitchTile(
            icon: Icons.notifications_active_rounded, 
            title: 'Bildirimler', 
            subtitle: notifOn ? 'Açık' : 'Kapalı', 
            value: notifOn, 
            onChanged: (v) => ref.read(notificationsProvider.notifier).state = v
          ),
          _buildSwitchTile(
            icon: Icons.dark_mode_rounded, 
            title: 'Karanlık Mod', 
            subtitle: darkOn ? 'Açık' : 'Kapalı', 
            value: darkOn, 
            onChanged: (v) => ref.read(darkModeProvider.notifier).state = v
          ),
          _buildSettingsTile(context, icon: Icons.language_rounded, title: 'Dil', subtitle: 'Türkçe'),

          const SizedBox(height: 24),
          _buildSectionHeader('HAKKINDA'),
          _buildSettingsTile(context, icon: Icons.info_outline_rounded, title: 'Versiyon', subtitle: 'v1.4.1 (Terminal Edition)'),
          _buildSettingsTile(context, icon: Icons.help_outline_rounded, title: 'Destek & İletişim', subtitle: ''),
          
          const SizedBox(height: 32),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Kriptograf PRO erişimi sonlandırıldı...'), 
                duration: Duration(seconds: 2),
                backgroundColor: AppTheme.bearish,
              ));
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.bearish,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppTheme.bearish)),
            ),
            child: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFF6B6F8E), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)) : null,
        trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$title menüsü yakında eklenecek.'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ));
        },
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)) : null,
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primary,
        activeTrackColor: AppTheme.primary.withValues(alpha: 0.3),
        inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
        inactiveThumbColor: Colors.white54,
      ),
    );
  }
}
