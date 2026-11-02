import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../theme/app_theme.dart';

class AddHabitSheet extends StatefulWidget {
  final Function(Habit) onAdd;

  const AddHabitSheet({super.key, required this.onAdd});

  @override
  State<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<AddHabitSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetController = TextEditingController(text: '1');
  final _unitController = TextEditingController(text: '');

  String _category = 'Mind';
  HabitType _type = HabitType.boolean;
  HabitFrequency _frequency = HabitFrequency.daily;

  final List<String> _categories = ['Mind', 'Health', 'Focus', 'Fitness', 'Routine'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final targetVal = double.tryParse(_targetController.text.trim()) ?? 1.0;

    final habit = Habit(
      id: 'h_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: _descriptionController.text.trim(),
      category: _category,
      type: _type,
      frequency: _frequency,
      targetValue: _type == HabitType.duration ? targetVal * 60 : targetVal,
      unit: _type == HabitType.duration ? 'min' : _unitController.text.trim(),
      createdAt: DateTime.now(),
    );

    widget.onAdd(habit);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('New habit', style: AppTypography.titleMedium),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title input
            TextField(
              controller: _titleController,
              style: AppTypography.body,
              decoration: InputDecoration(
                hintText: 'Habit title',
                hintStyle: AppTypography.labelMuted,
                filled: true,
                fillColor: AppColors.surfaceRaised,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderFocus),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Description input
            TextField(
              controller: _descriptionController,
              style: AppTypography.body,
              decoration: InputDecoration(
                hintText: 'Description or trigger (optional)',
                hintStyle: AppTypography.labelMuted,
                filled: true,
                fillColor: AppColors.surfaceRaised,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderFocus),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Type selector
            const Text('Tracking type', style: AppTypography.labelMuted),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildSegmentButton('Checkoff', _type == HabitType.boolean, () {
                  setState(() => _type = HabitType.boolean);
                }),
                const SizedBox(width: 8),
                _buildSegmentButton('Counter', _type == HabitType.counter, () {
                  setState(() {
                    _type = HabitType.counter;
                    _targetController.text = '20';
                    _unitController.text = 'pages';
                  });
                }),
                const SizedBox(width: 8),
                _buildSegmentButton('Timer', _type == HabitType.duration, () {
                  setState(() {
                    _type = HabitType.duration;
                    _targetController.text = '30';
                    _unitController.text = 'min';
                  });
                }),
              ],
            ),

            if (_type == HabitType.counter || _type == HabitType.duration) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _targetController,
                      keyboardType: TextInputType.number,
                      style: AppTypography.body,
                      decoration: InputDecoration(
                        hintText: _type == HabitType.duration ? 'Minutes' : 'Target',
                        hintStyle: AppTypography.labelMuted,
                        filled: true,
                        fillColor: AppColors.surfaceRaised,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                    ),
                  ),
                  if (_type == HabitType.counter) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _unitController,
                        style: AppTypography.body,
                        decoration: InputDecoration(
                          hintText: 'Unit (e.g. ml, pages)',
                          hintStyle: AppTypography.labelMuted,
                          filled: true,
                          fillColor: AppColors.surfaceRaised,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Frequency selector
            const Text('Frequency', style: AppTypography.labelMuted),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildSegmentButton('Daily', _frequency == HabitFrequency.daily, () {
                  setState(() => _frequency = HabitFrequency.daily);
                }),
                const SizedBox(width: 8),
                _buildSegmentButton('Weekdays', _frequency == HabitFrequency.weekdays, () {
                  setState(() => _frequency = HabitFrequency.weekdays);
                }),
                const SizedBox(width: 8),
                _buildSegmentButton('Weekends', _frequency == HabitFrequency.weekends, () {
                  setState(() => _frequency = HabitFrequency.weekends);
                }),
              ],
            ),
            const SizedBox(height: 16),

            // Category selector
            const Text('Category', style: AppTypography.labelMuted),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((c) {
                final isSelected = _category == c;
                return GestureDetector(
                  onTap: () => setState(() => _category = c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.surfaceRaised : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected ? AppColors.accent : AppColors.border,
                      ),
                    ),
                    child: Text(
                      c,
                      style: TextStyle(
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
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
                onPressed: _submit,
                child: const Text('Create habit', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceRaised : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppColors.borderFocus : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
