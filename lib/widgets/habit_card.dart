import 'dart:async';
import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../theme/app_theme.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final DateTime date;
  final VoidCallback onToggle;
  final ValueChanged<double>? onAddValue;
  final VoidCallback? onDelete;

  const HabitCard({
    super.key,
    required this.habit,
    required this.date,
    required this.onToggle,
    this.onAddValue,
    this.onDelete,
  });

  void _showTimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _DurationTimerDialog(habit: habit, date: date, onComplete: onToggle),
    );
  }

  void _showCounterSheet(BuildContext context) {
    double tempVal = habit.getValueOn(date);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(habit.title, style: AppTypography.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Target: ${habit.targetValue.round()} ${habit.unit}',
                    style: AppTypography.bodySecondary,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${tempVal.round()}',
                        style: AppTypography.numericLarge,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '/ ${habit.targetValue.round()} ${habit.unit}',
                        style: AppTypography.bodySecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StepButton(
                        label: '-1',
                        onTap: () {
                          if (tempVal > 0) setState(() => tempVal -= 1);
                        },
                      ),
                      _StepButton(
                        label: '+1',
                        onTap: () {
                          setState(() => tempVal += 1);
                        },
                      ),
                      _StepButton(
                        label: '+5',
                        onTap: () {
                          setState(() => tempVal += 5);
                        },
                      ),
                      _StepButton(
                        label: 'Complete',
                        onTap: () {
                          setState(() => tempVal = habit.targetValue);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.onAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        final delta = tempVal - habit.getValueOn(date);
                        onAddValue?.call(delta);
                        Navigator.pop(ctx);
                      },
                      child: const Text('Save progress', style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDone = habit.isCompletedOn(date);
    final streak = habit.calculateCurrentStreak(date);
    final strength = habit.calculateStrengthIndex(date);
    final stage = habit.automaticityStage;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone ? AppColors.surface.withOpacity(0.5) : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? AppColors.borderSubtle : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            habit.title,
                            style: TextStyle(
                              color: isDone ? AppColors.textSecondary : AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceRaised,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            habit.category,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (habit.description.isNotEmpty)
                      Text(
                        habit.description,
                        style: AppTypography.bodySecondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    // Telemetry row: Streak & Automaticity
                    Row(
                      children: [
                        Text(
                          'Streak: ${streak}d',
                          style: AppTypography.numericSmall,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Strength: ${strength.round()}% · $stage',
                          style: AppTypography.numericSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Action Trigger based on Type
              if (habit.type == HabitType.boolean)
                GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? AppColors.accent : Colors.transparent,
                      border: Border.all(
                        color: isDone ? AppColors.accent : AppColors.borderFocus,
                        width: 1.5,
                      ),
                    ),
                    child: isDone
                        ? const Icon(Icons.check, size: 18, color: AppColors.onAccent)
                        : null,
                  ),
                )
              else if (habit.type == HabitType.counter)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (habit.unit == 'ml') ...[
                      GestureDetector(
                        onTap: () => onAddValue?.call(250),
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceRaised,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '+250ml',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    GestureDetector(
                      onTap: () => _showCounterSheet(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceRaised,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                )
              else if (habit.type == HabitType.duration)
                GestureDetector(
                  onTap: () => _showTimerDialog(context),
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDone ? AppColors.surfaceRaised : AppColors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      isDone ? 'Completed' : 'Start timer',
                      style: TextStyle(
                        color: isDone ? AppColors.textSecondary : AppColors.onAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Quantitative progress bar for counter or duration
          if (habit.type != HabitType.boolean) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${habit.getValueOn(date).round()} / ${habit.targetValue.round()} ${habit.unit}',
                  style: AppTypography.numericSmall,
                ),
                Text(
                  '${(habit.progressOn(date) * 100).round()}%',
                  style: AppTypography.numericSmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: habit.progressOn(date),
                minHeight: 3,
                backgroundColor: AppColors.surfaceRaised,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isDone ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StepButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _DurationTimerDialog extends StatefulWidget {
  final Habit habit;
  final DateTime date;
  final VoidCallback onComplete;

  const _DurationTimerDialog({
    required this.habit,
    required this.date,
    required this.onComplete,
  });

  @override
  State<_DurationTimerDialog> createState() => _DurationTimerDialogState();
}

class _DurationTimerDialogState extends State<_DurationTimerDialog> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    final target = widget.habit.targetValue > 0 ? widget.habit.targetValue.toInt() : 1800;
    final current = widget.habit.getValueOn(widget.date).toInt();
    _remainingSeconds = (target - current) > 0 ? (target - current) : target;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds -= 1);
        } else {
          t.cancel();
          setState(() => _isRunning = false);
          widget.onComplete();
          Navigator.pop(context);
        }
      });
    }
  }

  String _format(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.habit.title, style: AppTypography.titleMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              _format(_remainingSeconds),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 40,
                fontWeight: FontWeight.w500,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _timer?.cancel();
            Navigator.pop(context);
          },
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _isRunning ? AppColors.surfaceRaised : AppColors.accent,
            foregroundColor: _isRunning ? AppColors.textPrimary : AppColors.onAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          onPressed: _toggle,
          child: Text(_isRunning ? 'Pause' : 'Start'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surfaceRaised,
            foregroundColor: AppColors.textPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          onPressed: () {
            _timer?.cancel();
            widget.onComplete();
            Navigator.pop(context);
          },
          child: const Text('Mark done'),
        ),
      ],
    );
  }
}
