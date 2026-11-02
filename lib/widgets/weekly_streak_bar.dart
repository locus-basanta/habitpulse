import 'package:flutter/material.dart';
import '../services/habit_store.dart';
import '../theme/app_theme.dart';

class WeeklyStreakBar extends StatelessWidget {
  final HabitStore store;

  const WeeklyStreakBar({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // 7 days ending at today or showing the current week
    final days = List.generate(7, (i) {
      return now.subtract(Duration(days: 6 - i));
    });

    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: days.map((date) {
          final isSelected = store.selectedDate.year == date.year &&
              store.selectedDate.month == date.month &&
              store.selectedDate.day == date.day;

          final isToday = now.year == date.year &&
              now.month == date.month &&
              now.day == date.day;

          // Calculate completed vs scheduled for this date
          int scheduled = store.habits.where((h) => h.isScheduledOn(date)).length;
          int completed = store.habits.where((h) => h.isScheduledOn(date) && h.isCompletedOn(date)).length;
          bool isAllDone = scheduled > 0 && completed >= scheduled;
          bool isPartial = scheduled > 0 && completed > 0 && completed < scheduled;

          return Expanded(
            child: GestureDetector(
              onTap: () => store.setSelectedDate(date),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surfaceRaised : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? (isToday ? AppColors.accent : AppColors.borderFocus)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayLabels[date.weekday - 1],
                      style: TextStyle(
                        color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Completion status indicator
                    if (isAllDone)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                        ),
                      )
                    else if (isPartial)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accent, width: 1.5),
                        ),
                      )
                    else
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.border,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
