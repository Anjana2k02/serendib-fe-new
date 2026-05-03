import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/dev_options_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    final devOptions = context.watch<DevOptionsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const _SectionHeader(title: 'General'),
          _SettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
              activeThumbColor: AppColors.primaryBrown,
            ),
          ),
          _SettingsTile(
            icon: Icons.location_on_outlined,
            title: 'Location Services',
            subtitle: 'Allow app to access your location',
            trailing: Switch(
              value: _locationEnabled,
              onChanged: (value) {
                setState(() {
                  _locationEnabled = value;
                });
              },
              activeThumbColor: AppColors.primaryBrown,
            ),
          ),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Coming soon',
            trailing: Switch(
              value: _darkModeEnabled,
              onChanged: (value) {
                setState(() {
                  _darkModeEnabled = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dark mode coming soon')),
                );
              },
              activeThumbColor: AppColors.primaryBrown,
            ),
          ),
          _SettingsTile(
            icon: Icons.developer_mode_outlined,
            title: 'Developer Options',
            subtitle: devOptions.developerOptionsEnabled ? 'Turn off' : 'Turn on',
            trailing: Switch(
              value: devOptions.developerOptionsEnabled,
              onChanged: (value) {
                context.read<DevOptionsProvider>().setDeveloperOptions(value);
              },
              activeThumbColor: AppColors.primaryBrown,
            ),
          ),

          const _SectionHeader(title: 'Content'),
          _SettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language settings coming soon')),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.download_outlined,
            title: 'Offline Content',
            subtitle: 'Manage downloaded maps and data',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Offline content coming soon')),
              );
            },
          ),

          const _SectionHeader(title: 'Privacy & Security'),
          _SettingsTile(
            icon: Icons.lock_outline,
            title: 'Privacy',
            subtitle: 'Control your privacy settings',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy settings coming soon')),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.security,
            title: 'Security',
            subtitle: 'Manage security preferences',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Security settings coming soon')),
              );
            },
          ),

          const _SectionHeader(title: 'About'),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terms of Service')),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy Policy')),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '1.0.0',
            onTap: () {},
          ),

          const SizedBox(height: AppConstants.spacingLg),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spacingLg,
        AppConstants.spacingLg,
        AppConstants.spacingLg,
        AppConstants.spacingSm,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.primaryBrown,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.creamWhite,
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        ),
        child: Icon(icon, color: AppColors.primaryBrown),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
