import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/models.dart';
import '../../providers/app_providers.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_formatters.dart';
import '../../widgets/common_widgets.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          userProfileAsync.when(
            data: (profile) => profile != null ? _buildProfileSection(profile) : const SizedBox(),
            loading: () => _buildProfileSectionSkeleton(),
            error: (_, _) => const SizedBox(),
          ),
          const SizedBox(height: 24),

          // Appearance Section
          _buildSectionHeader('Appearance'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.palette_outlined, color: theme.colorScheme.primary),
                  title: const Text('Theme'),
                  subtitle: const Text('Choose your preferred color theme'),
                  trailing: DropdownButton<ThemeMode>(
                    value: themeMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                      DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                    ],
                    onChanged: (value) => ref.read(themeModeProvider.notifier).state = value!,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.language_outlined, color: theme.colorScheme.primary),
                  title: const Text('Language'),
                  subtitle: const Text('Select your preferred language'),
                  trailing: DropdownButton<String>(
                    value: 'English',
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'English', child: Text('English')),
                      DropdownMenuItem(value: 'Spanish', child: Text('Spanish')),
                      DropdownMenuItem(value: 'French', child: Text('French')),
                    ],
                    onChanged: (value) {},
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          Card(
            child: Column(
              children: [
                _buildNotificationTile(
                  title: 'Risk Alerts',
                  subtitle: 'Receive notifications for high-risk alerts',
                  icon: Icons.warning_amber,
                  color: AppTheme.errorColor,
                  value: true,
                  onChanged: (v) {},
                ),
                _buildNotificationTile(
                  title: 'Fee Reminders',
                  subtitle: 'Get notified about upcoming and overdue fees',
                  icon: Icons.account_balance_wallet,
                  color: AppTheme.warningColor,
                  value: true,
                  onChanged: (v) {},
                ),
                _buildNotificationTile(
                  title: 'Attendance Alerts',
                  subtitle: 'Notifications for low attendance rates',
                  icon: Icons.assignment_ind,
                  color: AppTheme.primaryColor,
                  value: false,
                  onChanged: (v) {},
                ),
                _buildNotificationTile(
                  title: 'Exam Notifications',
                  subtitle: 'Reminders for upcoming exams and results',
                  icon: Icons.school,
                  color: AppTheme.secondaryColor,
                  value: true,
                  onChanged: (v) {},
                ),
                _buildNotificationTile(
                  title: 'Weekly Digest',
                  subtitle: 'Receive a weekly summary report via email',
                  icon: Icons.email,
                  color: AppTheme.infoColor,
                  value: false,
                  onChanged: (v) {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Data & Privacy Section
          _buildSectionHeader('Data & Privacy'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.download_outlined, color: theme.colorScheme.primary),
                  title: const Text('Export Data'),
                  subtitle: const Text('Download your data in CSV/JSON format'),
                  trailing: FilledButton.tonal(
                    onPressed: () => _exportData(),
                    child: const Text('Export'),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                  title: const Text('Delete Account'),
                  subtitle: const Text('Permanently delete your account and data'),
                  trailing: TextButton(
                    onPressed: () => _confirmDeleteAccount(),
                    child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  title: const Text('App Version'),
                  subtitle: const Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.article_outlined, color: theme.colorScheme.primary),
                  title: const Text('Privacy Policy'),
                  onTap: () => _showPolicy('Privacy Policy'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.description_outlined, color: theme.colorScheme.primary),
                  title: const Text('Terms of Service'),
                  onTap: () => _showPolicy('Terms of Service'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.help_outline, color: theme.colorScheme.primary),
                  title: const Text('Help & Support'),
                  onTap: () => _showHelp(),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.bug_report_outlined, color: theme.colorScheme.primary),
                  title: const Text('Report a Bug'),
                  onTap: () => _reportBug(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Danger Zone
          _buildSectionHeader('Account'),
          Card(
            child: ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text('Sign Out', style: TextStyle(color: theme.colorScheme.error)),
              subtitle: const Text('Sign out of your account'),
              onTap: _handleSignOut,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(UserModel profile) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            AvatarWidget(
              firstName: profile.displayName.split(' ').first,
              lastName: profile.displayName.split(' ').length > 1 ? profile.displayName.split(' ').last : '',
              radius: 30,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.displayName, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(profile.email, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Chip(
                        label: Text(profile.role.displayName),
                        avatar: Icon(_getRoleIcon(profile.role), size: 16),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(profile.districtId.substring(0, 8)),
                        avatar: const Icon(Icons.location_city, size: 16),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () => _editProfile(),
              child: const Text('Edit Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSectionSkeleton() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(radius: 30, backgroundColor: Colors.grey[300]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 24, width: 200, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Container(height: 16, width: 150, color: Colors.grey[300]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Icons.supervisor_account;
      case UserRole.districtAdmin:
        return Icons.location_city;
      case UserRole.schoolAdmin:
        return Icons.school;
      case UserRole.teacher:
        return Icons.person;
      case UserRole.viewer:
        return Icons.visibility;
    }
  }

  void _editProfile() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit profile feature coming soon')));
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data export feature coming soon')));
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This action is irreversible. All your data will be permanently deleted. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deletion not implemented')));
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showPolicy(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('Policy content would be displayed here.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _showHelp() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Help & support coming soon')));
  }

  void _reportBug() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bug reporting coming soon')));
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out')),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authServiceProvider).signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }
}