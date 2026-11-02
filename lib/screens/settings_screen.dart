import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/habit_store.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final HabitStore store;

  const SettingsScreen({super.key, required this.store});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _streakProtection = true;
  bool _hapticFeedback = true;

  void _exportData() {
    final jsonStr = widget.store.exportBackupJson();
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Habit data copied to clipboard as JSON.'),
        backgroundColor: AppColors.surfaceRaised,
      ),
    );
  }

  void _showImportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Import backup', style: AppTypography.titleMedium),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste valid JSON backup string below:',
              style: AppTypography.bodySecondary,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 5,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceRaised,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.onAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final ok = widget.store.importBackupJson(controller.text.trim());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Backup successfully imported.' : 'Invalid JSON format.'),
                  backgroundColor: ok ? AppColors.accent : AppColors.danger,
                ),
              );
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Reset to demo data', style: AppTypography.titleMedium),
        content: const Text(
          'This will overwrite current habits with standard 30-day benchmark data.',
          style: AppTypography.bodySecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              widget.store.resetToDemoData();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reset to benchmark dataset complete.'),
                  backgroundColor: AppColors.surfaceRaised,
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings', style: AppTypography.titleMedium),
        titleSpacing: 20,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          // User Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'B',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Basanta', style: AppTypography.titleMedium),
                    Text('Local storage profile', style: AppTypography.bodySecondary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('PREFERENCES', style: AppTypography.labelMuted),
          const SizedBox(height: 8),
          _buildToggleItem(
            'Streak grace protection',
            'Allows 1 missed day per month without resetting sequence',
            _streakProtection,
            (v) => setState(() => _streakProtection = v),
          ),
          _buildToggleItem(
            'Haptic feedback',
            'Tactile impulse when checking off rituals',
            _hapticFeedback,
            (v) => setState(() => _hapticFeedback = v),
          ),

          const SizedBox(height: 24),
          const Text('DATA & BACKUP', style: AppTypography.labelMuted),
          const SizedBox(height: 8),
          _buildActionItem('Export JSON backup', 'Copy full historical logs to clipboard', _exportData),
          _buildActionItem('Import JSON backup', 'Restore habits from backup text', _showImportDialog),
          _buildActionItem('Reset to benchmark data', 'Re-seed with 30-day sample data', _confirmReset, isDanger: true),

          const SizedBox(height: 24),
          const Text('SYSTEM', style: AppTypography.labelMuted),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Application version', style: AppTypography.body),
                    Text('1.0.0 (Release)', style: AppTypography.numericSmall),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Framework', style: AppTypography.body),
                    Text('Flutter 3.24.5', style: AppTypography.numericSmall),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.body),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.bodySecondary),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.accent,
            inactiveTrackColor: AppColors.surfaceRaised,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(String title, String subtitle, VoidCallback onTap, {bool isDanger = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDanger ? AppColors.dangerMuted : AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDanger ? AppColors.danger : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.bodySecondary),
              ],
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: isDanger ? AppColors.danger : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
