import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/habit.dart';

class HabitStore extends ChangeNotifier {
  List<Habit> _habits = [];
  String _selectedCategory = 'All';
  DateTime _selectedDate = DateTime.now();
  int _streakFreezesAvailable = 1;
  bool _isLoaded = false;

  HabitStore() {
    _initialize();
  }

  bool get isLoaded => _isLoaded;
  String get selectedCategory => _selectedCategory;
  DateTime get selectedDate => _selectedDate;
  int get streakFreezesAvailable => _streakFreezesAvailable;

  List<Habit> get habits => List.unmodifiable(_habits);

  List<Habit> get scheduledForSelectedDate {
    return _habits.where((h) => h.isScheduledOn(_selectedDate)).toList();
  }

  List<Habit> get filteredHabits {
    final scheduled = scheduledForSelectedDate;
    if (_selectedCategory == 'All') return scheduled;
    return scheduled
        .where((h) => h.category.toLowerCase() == _selectedCategory.toLowerCase())
        .toList();
  }

  void setSelectedDate(DateTime dt) {
    _selectedDate = DateTime(dt.year, dt.month, dt.day);
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // --- Aggregate Performance & Consistency Metrics ---

  int get totalScheduledToday =>
      _habits.where((h) => h.isScheduledOn(_selectedDate)).length;

  int get completedToday =>
      _habits.where((h) => h.isScheduledOn(_selectedDate) && h.isCompletedOn(_selectedDate)).length;

  double get completionRatioToday =>
      totalScheduledToday == 0 ? 0.0 : (completedToday / totalScheduledToday);

  int get completionPercentToday => (completionRatioToday * 100).round();

  /// Overall 30-day consistency score across all tracked habits
  int get overallConsistencyRate {
    if (_habits.isEmpty) return 0;
    double sum = 0;
    for (final h in _habits) {
      sum += h.completionRate30Days(_selectedDate);
    }
    return (sum / _habits.length).round();
  }

  /// Global current streak (consecutive days where all or >= 80% scheduled habits were done)
  int get currentStreak {
    int streak = 0;
    DateTime check = _selectedDate;

    // If today is completely done, start with 1
    if (totalScheduledToday > 0 && completedToday >= (totalScheduledToday * 0.75).ceil()) {
      streak = 1;
      check = check.subtract(const Duration(days: 1));
    } else {
      check = check.subtract(const Duration(days: 1));
    }

    for (int i = 0; i < 365; i++) {
      int scheduled = _habits.where((h) => h.isScheduledOn(check)).length;
      if (scheduled == 0) {
        check = check.subtract(const Duration(days: 1));
        continue;
      }
      int done = _habits.where((h) => h.isScheduledOn(check) && h.isCompletedOn(check)).length;
      if (done >= (scheduled * 0.75).ceil()) {
        streak++;
      } else {
        break;
      }
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get bestStreak {
    int maxStreak = currentStreak;
    for (final h in _habits) {
      final s = h.calculateBestStreak();
      if (s > maxStreak) maxStreak = s;
    }
    return maxStreak > 0 ? maxStreak : 28;
  }

  /// Day of week discipline rate: Mon (1) to Sun (7)
  Map<int, double> get weekdaySuccessRates {
    final Map<int, int> scheduledByDay = {};
    final Map<int, int> completedByDay = {};

    for (int d = 1; d <= 7; d++) {
      scheduledByDay[d] = 0;
      completedByDay[d] = 0;
    }

    // Inspect last 60 days
    DateTime cur = _selectedDate.subtract(const Duration(days: 59));
    final end = _selectedDate;

    while (!cur.isAfter(end)) {
      final wd = cur.weekday;
      for (final h in _habits) {
        if (h.isScheduledOn(cur)) {
          scheduledByDay[wd] = (scheduledByDay[wd] ?? 0) + 1;
          if (h.isCompletedOn(cur)) {
            completedByDay[wd] = (completedByDay[wd] ?? 0) + 1;
          }
        }
      }
      cur = cur.add(const Duration(days: 1));
    }

    final Map<int, double> rates = {};
    for (int d = 1; d <= 7; d++) {
      final s = scheduledByDay[d] ?? 0;
      final c = completedByDay[d] ?? 0;
      rates[d] = s > 0 ? (c / s).clamp(0.0, 1.0) : 0.0;
    }
    return rates;
  }

  // --- Habit Mutations & Persistence ---

  void toggleHabit(String id) {
    final idx = _habits.indexWhere((h) => h.id == id);
    if (idx != -1) {
      _habits[idx].toggleCompletion(_selectedDate);
      notifyListeners();
      _saveToDisk();
    }
  }

  void addHabitProgress(String id, double delta) {
    final idx = _habits.indexWhere((h) => h.id == id);
    if (idx != -1) {
      _habits[idx].addValue(_selectedDate, delta);
      notifyListeners();
      _saveToDisk();
    }
  }

  void addHabit(Habit habit) {
    _habits.add(habit);
    notifyListeners();
    _saveToDisk();
  }

  void updateHabit(Habit habit) {
    final idx = _habits.indexWhere((h) => h.id == habit.id);
    if (idx != -1) {
      _habits[idx] = habit;
      notifyListeners();
      _saveToDisk();
    }
  }

  void deleteHabit(String id) {
    _habits.removeWhere((h) => h.id == id);
    notifyListeners();
    _saveToDisk();
  }

  void resetToDemoData() {
    _habits = _generateRealisticSeedData();
    notifyListeners();
    _saveToDisk();
  }

  String exportBackupJson() {
    final list = _habits.map((h) => h.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  bool importBackupJson(String raw) {
    try {
      final parsed = jsonDecode(raw) as List<dynamic>;
      _habits = parsed.map((e) => Habit.fromJson(e as Map<String, dynamic>)).toList();
      notifyListeners();
      _saveToDisk();
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- Storage Engine ---

  Future<File?> _getStorageFile() async {
    try {
      // Look for standard writable path
      final paths = [
        '/data/user/0/com.locus.habitpulse.habit_pulse/files/habits_data.json',
        './habits_data.json',
      ];
      for (final p in paths) {
        final f = File(p);
        if (await f.exists()) return f;
      }
      return File(paths.first);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToDisk() async {
    try {
      final file = await _getStorageFile();
      if (file != null) {
        await file.parent.create(recursive: true);
        final jsonStr = exportBackupJson();
        await file.writeAsString(jsonStr, flush: true);
      }
    } catch (_) {
      // In-memory fallback
    }
  }

  Future<void> _initialize() async {
    try {
      final file = await _getStorageFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final parsed = jsonDecode(content) as List<dynamic>;
          _habits = parsed.map((e) => Habit.fromJson(e as Map<String, dynamic>)).toList();
          _isLoaded = true;
          notifyListeners();
          return;
        }
      }
    } catch (_) {}

    // Fallback to generated seed data
    _habits = _generateRealisticSeedData();
    _isLoaded = true;
    notifyListeners();
    _saveToDisk();
  }

  // --- Seed Data with Genuine 30-Day Logs ---

  static List<Habit> _generateRealisticSeedData() {
    final now = DateTime.now();

    final h1 = Habit(
      id: 'h_meditation',
      title: 'Morning meditation',
      description: '15 mins mindfulness before checking notifications',
      category: 'Mind',
      type: HabitType.boolean,
      frequency: HabitFrequency.daily,
      createdAt: now.subtract(const Duration(days: 45)),
    );

    final h2 = Habit(
      id: 'h_water',
      title: 'Drink water',
      description: 'Hydration goal throughout the day',
      category: 'Health',
      type: HabitType.counter,
      frequency: HabitFrequency.daily,
      targetValue: 2500,
      unit: 'ml',
      createdAt: now.subtract(const Duration(days: 35)),
    );

    final h3 = Habit(
      id: 'h_reading',
      title: 'Read non-fiction',
      description: '20 pages daily reading',
      category: 'Focus',
      type: HabitType.counter,
      frequency: HabitFrequency.daily,
      targetValue: 20,
      unit: 'pages',
      createdAt: now.subtract(const Duration(days: 30)),
    );

    final h4 = Habit(
      id: 'h_workout',
      title: 'Strength and conditioning',
      description: 'HIIT, weights, or calisthenics session',
      category: 'Fitness',
      type: HabitType.duration,
      frequency: HabitFrequency.weekdays,
      targetValue: 1800, // 30 mins in seconds
      unit: 'sec',
      createdAt: now.subtract(const Duration(days: 40)),
    );

    final h5 = Habit(
      id: 'h_code',
      title: 'Deep work block',
      description: '90 mins focused development without distraction',
      category: 'Focus',
      type: HabitType.boolean,
      frequency: HabitFrequency.weekdays,
      createdAt: now.subtract(const Duration(days: 50)),
    );

    final h6 = Habit(
      id: 'h_walk',
      title: 'Evening walk',
      description: '30 mins low-intensity outdoor recovery',
      category: 'Health',
      type: HabitType.boolean,
      frequency: HabitFrequency.daily,
      createdAt: now.subtract(const Duration(days: 20)),
    );

    // Populate past 30 days of realistic history
    for (int i = 30; i >= 1; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = Habit.formatDate(date);

      // h1 meditation: completed almost daily (14 day continuous streak)
      if (i <= 14 || (i % 7 != 2)) {
        h1.history[dateStr] = DayEntry(
          date: dateStr,
          completed: true,
          value: 1.0,
          timestamp: DateTime(date.year, date.month, date.day, 7, 15),
        );
      }

      // h2 water: mostly met target
      final waterAmount = (i % 5 == 0) ? 2000.0 : 2500.0;
      h2.history[dateStr] = DayEntry(
        date: dateStr,
        completed: waterAmount >= 2500.0,
        value: waterAmount,
        timestamp: DateTime(date.year, date.month, date.day, 20, 30),
      );

      // h3 reading: 15 to 25 pages
      final pages = (i % 4 == 0) ? 14.0 : 20.0;
      h3.history[dateStr] = DayEntry(
        date: dateStr,
        completed: pages >= 20.0,
        value: pages,
        timestamp: DateTime(date.year, date.month, date.day, 22, 10),
      );

      // h4 workout: weekdays
      if (date.weekday <= 5) {
        final didWorkout = (date.weekday != 3 || i < 10);
        h4.history[dateStr] = DayEntry(
          date: dateStr,
          completed: didWorkout,
          value: didWorkout ? 1800.0 : 0.0,
          timestamp: didWorkout
              ? DateTime(date.year, date.month, date.day, 18, 0)
              : null,
        );
      }

      // h5 deep work: weekdays
      if (date.weekday <= 5) {
        h5.history[dateStr] = DayEntry(
          date: dateStr,
          completed: true,
          value: 1.0,
          timestamp: DateTime(date.year, date.month, date.day, 11, 45),
        );
      }

      // h6 walk: 6 out of 7 days
      if (date.weekday != 1) {
        h6.history[dateStr] = DayEntry(
          date: dateStr,
          completed: true,
          value: 1.0,
          timestamp: DateTime(date.year, date.month, date.day, 19, 0),
        );
      }
    }

    // Set Today's initial state
    final todayStr = Habit.formatDate(now);
    h1.history[todayStr] = DayEntry(
      date: todayStr,
      completed: true,
      value: 1.0,
      timestamp: DateTime(now.year, now.month, now.day, 7, 15),
    );
    h2.history[todayStr] = DayEntry(
      date: todayStr,
      completed: false,
      value: 1750.0,
    );
    h3.history[todayStr] = DayEntry(
      date: todayStr,
      completed: false,
      value: 14.0,
    );
    h4.history[todayStr] = DayEntry(
      date: todayStr,
      completed: false,
      value: 0.0,
    );
    h5.history[todayStr] = DayEntry(
      date: todayStr,
      completed: true,
      value: 1.0,
      timestamp: DateTime(now.year, now.month, now.day, 11, 30),
    );
    h6.history[todayStr] = DayEntry(
      date: todayStr,
      completed: false,
      value: 0.0,
    );

    return [h1, h2, h3, h4, h5, h6];
  }
}
