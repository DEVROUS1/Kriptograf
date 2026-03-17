import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          _buildSettingsTile(icon: Icons.person_rounded, title: 'Profil Bilgileri', subtitle: 'Kriptograf PRO Üyesi'),
          _buildSettingsTile(icon: Icons.security_rounded, title: 'Güvenlik & 2FA', subtitle: 'Aktif'),
          
          const SizedBox(height: 24),
          _buildSectionHeader('API ENTEGRASYONU'),
          _buildSettingsTile(icon: Icons.key_rounded, title: 'Binance API Key', subtitle: 'Bağlandı'),
          _buildSettingsTile(icon: Icons.webhook_rounded, title: 'Webhook URL', subtitle: 'Ayarlanmadı'),

          const SizedBox(height: 24),
          _buildSectionHeader('UYGULAMA'),
          _buildSettingsTile(icon: Icons.notifications_active_rounded, title: 'Bildirimler', subtitle: 'Açık', isSwitch: true, switchValue: true),
          _buildSettingsTile(icon: Icons.dark_mode_rounded, title: 'Karanlık Mod', subtitle: 'Açık', isSwitch: true, switchValue: true),
          _buildSettingsTile(icon: Icons.language_rounded, title: 'Dil', subtitle: 'Türkçe'),

          const SizedBox(height: 24),
          _buildSectionHeader('HAKKINDA'),
          _buildSettingsTile(icon: Icons.info_outline_rounded, title: 'Versiyon', subtitle: 'v1.4.0 (Terminal Edition)'),
          _buildSettingsTile(icon: Icons.help_outline_rounded, title: 'Destek & İletişim', subtitle: ''),
          
          const SizedBox(height: 32),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Çıkış yapıldı.')));
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

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isSwitch = false,
    bool switchValue = false,
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
        trailing: isSwitch
            ? Switch(
                value: switchValue,
                onChanged: (val) {},
                activeColor: AppTheme.primary,
              )
            : const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
        onTap: isSwitch ? null : () {},
      ),
    );
  }
}
