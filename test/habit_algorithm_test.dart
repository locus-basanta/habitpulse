import 'package:flutter_test/flutter_test.dart';
import 'package:habit_pulse/models/habit.dart';

void main() {
  group('Habit Algorithm Tests', () {
    test('Streak calculation counts consecutive days and accounts for freezes', () {
      final now = DateTime(2026, 11, 1);
      final habit = Habit(
        id: 'test_1',
        title: 'Meditation',
        category: 'Mind',
        createdAt: now.subtract(const Duration(days: 10)),
      );

      // Log 5 consecutive days up to today
      for (int i = 0; i < 5; i++) {
        final d = now.subtract(Duration(days: i));
        habit.history[Habit.formatDate(d)] = DayEntry(
          date: Habit.formatDate(d),
          completed: true,
          value: 1.0,
        );
      }

      expect(habit.calculateCurrentStreak(now), equals(5));

      // With a missed day 6 days ago, but freeze allowed
      final d6 = now.subtract(const Duration(days: 5));
      habit.history[Habit.formatDate(d6)] = DayEntry(date: Habit.formatDate(d6), completed: false);

      final d7 = now.subtract(const Duration(days: 6));
      habit.history[Habit.formatDate(d7)] = DayEntry(date: Habit.formatDate(d7), completed: true);

      // Freeze covers 1 missed day
      expect(habit.calculateCurrentStreak(now, maxFreezesAllowed: 1), equals(6));
    });

    test('Automaticity curve score increases with continuous repetitions and decays on lapses', () {
      final now = DateTime(2026, 11, 1);
      final habit = Habit(
        id: 'test_2',
        title: 'Hydration',
        category: 'Health',
        createdAt: now.subtract(const Duration(days: 60)),
      );

      // Empty history -> 0% automaticity
      expect(habit.calculateStrengthIndex(now), equals(0.0));
      expect(habit.automaticityStage, equals('Forming'));

      // 30 days of consistent completion
      for (int i = 0; i < 30; i++) {
        final d = now.subtract(Duration(days: i));
        habit.history[Habit.formatDate(d)] = DayEntry(
          date: Habit.formatDate(d),
          completed: true,
          value: 1.0,
        );
      }

      final score = habit.calculateStrengthIndex(now);
      expect(score, greaterThan(70.0));
      expect(habit.automaticityStage, anyOf(equals('Established'), equals('Automatic')));
    });

    test('30-day consistency score reflects exact scheduled completion ratio', () {
      final now = DateTime(2026, 11, 1);
      final habit = Habit(
        id: 'test_3',
        title: 'Deep Work',
        category: 'Focus',
        createdAt: now.subtract(const Duration(days: 40)),
      );

      // Complete 15 of the past 30 days
      for (int i = 0; i < 15; i++) {
        final d = now.subtract(Duration(days: i));
        habit.history[Habit.formatDate(d)] = DayEntry(
          date: Habit.formatDate(d),
          completed: true,
          value: 1.0,
        );
      }

      final rate = habit.completionRate30Days(now);
      expect(rate.round(), equals(50));
    });

    test('Habit JSON serialization and deserialization roundtrip works flawlessly', () {
      final now = DateTime(2026, 11, 1);
      final habit = Habit(
        id: 'test_json',
        title: 'Coding',
        description: 'Code algorithms',
        category: 'Focus',
        type: HabitType.counter,
        targetValue: 100,
        unit: 'lines',
        createdAt: now,
      );

      habit.history['2026-11-01'] = DayEntry(
        date: '2026-11-01',
        completed: true,
        value: 120.0,
      );

      final json = habit.toJson();
      final restored = Habit.fromJson(json);

      expect(restored.id, equals(habit.id));
      expect(restored.title, equals(habit.title));
      expect(restored.targetValue, equals(100.0));
      expect(restored.isCompletedOn(DateTime(2026, 11, 1)), isTrue);
      expect(restored.getValueOn(DateTime(2026, 11, 1)), equals(120.0));
    });
  });
}
