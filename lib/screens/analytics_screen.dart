import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/habit_store.dart';
import '../theme/app_theme.dart';

class AnalyticsScreen extends StatelessWidget {
  final HabitStore store;

  const AnalyticsScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final weekdayRates = store.weekdaySuccessRates;
        final weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

        // Total lifetime logs
        int totalLogs = 0;
        for (final h in store.habits) {
          totalLogs += h.history.values.where((e) => e.completed).length;
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Analytics', style: AppTypography.titleMedium),
            titleSpacing: 20,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3 Key Metrics Row
                Row(
                  children: [
                    _buildStatCard('Consistency', '${store.overallConsistencyRate}%', 'Past 30 days'),
                    const SizedBox(width: 8),
                    _buildStatCard('Current streak', '${store.currentStreak}d', 'Active sequence'),
                    const SizedBox(width: 8),
                    _buildStatCard('Total logged', '$totalLogs', 'Checkoffs'),
                  ],
                ),
                const SizedBox(height: 16),

                // 30-Day Activity Heat Matrix
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('30-day activity matrix', style: AppTypography.titleMedium),
                          Text('${store.overallConsistencyRate}% avg', style: AppTypography.numericSmall),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Daily completion density across all scheduled rituals',
                        style: AppTypography.bodySecondary,
                      ),
                      const SizedBox(height: 16),
                      _buildHeatMatrix(store),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Weekday Discipline Distribution
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Weekday consistency', style: AppTypography.titleMedium),
                      const SizedBox(height: 4),
                      const Text(
                        'Success rate by day of week over the past 60 days',
                        style: AppTypography.bodySecondary,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(7, (i) {
                          final wd = i + 1;
                          final rate = weekdayRates[wd] ?? 0.0;
                          final pct = (rate * 100).round();
                          final isHighest = rate >= 0.85;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$pct%',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 24,
                                height: 80 * rate + 6,
                                decoration: BoxDecoration(
                                  color: isHighest ? AppColors.accent : AppColors.surfaceRaised,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: isHighest ? AppColors.accent : AppColors.border,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                weekdayLabels[i],
                                style: TextStyle(
                                  color: isHighest ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: isHighest ? FontWeight.w500 : FontWeight.w400,
                                ),
                              ),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Automaticity & Strength Index Table
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Habit automaticity', style: AppTypography.titleMedium),
                      const SizedBox(height: 4),
                      const Text(
                        'Behavioral automaticity curve (Lally model, 60-day asymptote)',
                        style: AppTypography.bodySecondary,
                      ),
                      const SizedBox(height: 14),
                      ...store.habits.map((h) {
                        final strength = h.calculateStrengthIndex(store.selectedDate);
                        final stage = h.automaticityStage;
                        final streak = h.calculateCurrentStreak(store.selectedDate);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(h.title, style: AppTypography.body),
                                  Text(
                                    '${strength.round()}% · $stage',
                                    style: AppTypography.numericSmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: strength / 100.0,
                                  minHeight: 4,
                                  backgroundColor: AppColors.surfaceRaised,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    strength >= 75.0
                                        ? AppColors.accent
                                        : (strength >= 50.0
                                            ? AppColors.catHealth
                                            : AppColors.textSecondary),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sequence: ${streak}d · 30d retention: ${h.completionRate30Days(store.selectedDate).round()}%',
                                style: AppTypography.labelMuted,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.labelMuted),
            const SizedBox(height: 4),
            Text(value, style: AppTypography.numericMedium),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatMatrix(HabitStore store) {
    final now = DateTime.now();
    // 30 days
    final days = List.generate(30, (i) => now.subtract(Duration(days: 29 - i)));

    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: days.map((d) {
        int scheduled = store.habits.where((h) => h.isScheduledOn(d)).length;
        int completed = store.habits.where((h) => h.isScheduledOn(d) && h.isCompletedOn(d)).length;
        double ratio = scheduled > 0 ? (completed / scheduled) : 0.0;

        Color cellColor;
        if (ratio == 0) {
          cellColor = AppColors.surfaceRaised;
        } else if (ratio < 0.5) {
          cellColor = AppColors.accent.withOpacity(0.3);
        } else if (ratio < 0.9) {
          cellColor = AppColors.accent.withOpacity(0.65);
        } else {
          cellColor = AppColors.accent;
        }

        return Tooltip(
          message: '${Habit.formatDate(d)}: $completed/$scheduled',
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: cellColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }).toList(),
    );
  }
}
