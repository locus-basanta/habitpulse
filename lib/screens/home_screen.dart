import 'package:flutter/material.dart';
import '../services/habit_store.dart';
import '../theme/app_theme.dart';
import '../widgets/progress_ring.dart';
import '../widgets/weekly_streak_bar.dart';
import '../widgets/habit_card.dart';

class HomeScreen extends StatelessWidget {
  final HabitStore store;

  const HomeScreen({super.key, required this.store});

  String _formatHeaderDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return '${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final remaining = store.totalScheduledToday - store.completedToday;
        final isToday = DateTime.now().year == store.selectedDate.year &&
            DateTime.now().month == store.selectedDate.month &&
            DateTime.now().day == store.selectedDate.day;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar
            SliverAppBar(
              floating: true,
              pinned: true,
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              titleSpacing: 20,
              title: const Text(
                'HabitPulse',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                ),
              ),
              actions: [
                if (!isToday)
                  TextButton(
                    onPressed: () => store.setSelectedDate(DateTime.now()),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Jump to today', style: TextStyle(fontSize: 12)),
                  ),
                const SizedBox(width: 8),
              ],
            ),

            // Content Body
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),

                  // Date label & Section Title
                  Text(
                    _formatHeaderDate(store.selectedDate),
                    style: AppTypography.labelMuted,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isToday ? 'Today' : 'Overview',
                        style: AppTypography.titleLarge,
                      ),
                      Text(
                        '$remaining remaining',
                        style: AppTypography.numericSmall,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Telemetry Dashboard Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${store.completedToday} of ${store.totalScheduledToday} completed',
                                style: AppTypography.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isToday && remaining == 0
                                    ? 'Daily scheduled goals achieved.'
                                    : 'Track consistency and habit automaticity.',
                                style: AppTypography.bodySecondary,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  _buildStatItem('Streak', '${store.currentStreak}d'),
                                  const SizedBox(width: 16),
                                  _buildStatItem('30d rate', '${store.overallConsistencyRate}%'),
                                  const SizedBox(width: 16),
                                  _buildStatItem('Best', '${store.bestStreak}d'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ProgressRingWidget(
                          progress: store.completionRatioToday,
                          percentage: store.completionPercentToday,
                          size: 72,
                          strokeWidth: 5,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 7-day strip
                  WeeklyStreakBar(store: store),

                  const SizedBox(height: 20),

                  // Category Filter Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Mind', 'Health', 'Focus', 'Fitness', 'Routine']
                          .map((cat) {
                        final isSelected = store.selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => store.setCategory(cat),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.surfaceRaised : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected ? AppColors.borderFocus : AppColors.border,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Habit Cards
                  if (store.filteredHabits.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      alignment: Alignment.center,
                      child: const Text(
                        'No habits scheduled for this day.',
                        style: AppTypography.bodySecondary,
                      ),
                    )
                  else
                    ...store.filteredHabits.map((h) {
                      return HabitCard(
                        habit: h,
                        date: store.selectedDate,
                        onToggle: () => store.toggleHabit(h.id),
                        onAddValue: (delta) => store.addHabitProgress(h.id, delta),
                      );
                    }),

                  const SizedBox(height: 60),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMuted),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.numericMedium),
      ],
    );
  }
}
