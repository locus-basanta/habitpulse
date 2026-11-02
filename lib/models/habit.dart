import 'dart:math';

enum HabitType {
  boolean,
  counter,
  duration,
}

enum HabitFrequency {
  daily,
  weekdays,
  weekends,
  custom,
}

class DayEntry {
  final String date; // YYYY-MM-DD
  bool completed;
  double value;
  DateTime? timestamp;
  String? note;

  DayEntry({
    required this.date,
    this.completed = false,
    this.value = 0.0,
    this.timestamp,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'completed': completed,
        'value': value,
        'timestamp': timestamp?.toIso8601String(),
        'note': note,
      };

  factory DayEntry.fromJson(Map<String, dynamic> json) => DayEntry(
        date: json['date'] as String,
        completed: json['completed'] as bool? ?? false,
        value: (json['value'] as num?)?.toDouble() ?? 0.0,
        timestamp: json['timestamp'] != null
            ? DateTime.tryParse(json['timestamp'] as String)
            : null,
        note: json['note'] as String?,
      );
}

class Habit {
  final String id;
  String title;
  String description;
  String category;
  HabitType type;
  HabitFrequency frequency;
  List<int> scheduledDays; // 1 = Mon, ..., 7 = Sun
  double targetValue;
  String unit;
  DateTime createdAt;
  Map<String, DayEntry> history; // key: YYYY-MM-DD

  Habit({
    required this.id,
    required this.title,
    this.description = '',
    required this.category,
    this.type = HabitType.boolean,
    this.frequency = HabitFrequency.daily,
    List<int>? scheduledDays,
    this.targetValue = 1.0,
    this.unit = '',
    DateTime? createdAt,
    Map<String, DayEntry>? history,
  })  : scheduledDays = scheduledDays ?? [1, 2, 3, 4, 5, 6, 7],
        createdAt = createdAt ?? DateTime.now(),
        history = history ?? {};

  static String formatDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  bool isScheduledOn(DateTime dt) {
    switch (frequency) {
      case HabitFrequency.daily:
        return true;
      case HabitFrequency.weekdays:
        return dt.weekday >= 1 && dt.weekday <= 5;
      case HabitFrequency.weekends:
        return dt.weekday == 6 || dt.weekday == 7;
      case HabitFrequency.custom:
        return scheduledDays.contains(dt.weekday);
    }
  }

  DayEntry getEntry(DateTime dt) {
    final key = formatDate(dt);
    if (!history.containsKey(key)) {
      history[key] = DayEntry(date: key);
    }
    return history[key]!;
  }

  bool isCompletedOn(DateTime dt) {
    final key = formatDate(dt);
    return history[key]?.completed ?? false;
  }

  double getValueOn(DateTime dt) {
    final key = formatDate(dt);
    return history[key]?.value ?? 0.0;
  }

  double progressOn(DateTime dt) {
    if (targetValue <= 0) return 0.0;
    if (type == HabitType.boolean) {
      return isCompletedOn(dt) ? 1.0 : 0.0;
    }
    return (getValueOn(dt) / targetValue).clamp(0.0, 1.0);
  }

  void toggleCompletion(DateTime dt) {
    final entry = getEntry(dt);
    entry.completed = !entry.completed;
    if (entry.completed) {
      entry.timestamp = DateTime.now();
      if (type == HabitType.counter || type == HabitType.duration) {
        if (entry.value < targetValue) {
          entry.value = targetValue;
        }
      } else {
        entry.value = 1.0;
      }
    } else {
      entry.timestamp = null;
      if (type == HabitType.counter || type == HabitType.duration) {
        entry.value = 0.0;
      } else {
        entry.value = 0.0;
      }
    }
  }

  void addValue(DateTime dt, double delta) {
    final entry = getEntry(dt);
    entry.value = max(0.0, entry.value + delta);
    if (entry.value >= targetValue) {
      entry.completed = true;
      entry.timestamp ??= DateTime.now();
    } else {
      entry.completed = false;
    }
  }

  int calculateCurrentStreak(DateTime referenceDate, {int maxFreezesAllowed = 1}) {
    final today = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
    int streak = 0;
    int freezesUsed = 0;

    bool todayCompleted = isCompletedOn(today);
    DateTime checkDate;

    if (todayCompleted) {
      streak = 1;
      checkDate = today.subtract(const Duration(days: 1));
    } else {
      checkDate = today.subtract(const Duration(days: 1));
    }

    for (int i = 0; i < 365; i++) {
      if (checkDate.isBefore(DateTime(createdAt.year, createdAt.month, createdAt.day))) {
        break;
      }

      final isScheduled = isScheduledOn(checkDate);
      if (!isScheduled) {
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      }

      if (isCompletedOn(checkDate)) {
        streak++;
      } else {
        if (freezesUsed < maxFreezesAllowed) {
          freezesUsed++;
        } else {
          break;
        }
      }
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int calculateBestStreak() {
    if (history.isEmpty) return 0;

    final sortedDates = history.keys.toList()..sort();
    if (sortedDates.isEmpty) return 0;

    DateTime current = DateTime.parse(sortedDates.first);
    final end = DateTime.now();

    int maxStreak = 0;
    int currentStreak = 0;

    while (!current.isAfter(end)) {
      if (isScheduledOn(current)) {
        if (isCompletedOn(current)) {
          currentStreak++;
          if (currentStreak > maxStreak) {
            maxStreak = currentStreak;
          }
        } else {
          currentStreak = 0;
        }
      }
      current = current.add(const Duration(days: 1));
    }

    return maxStreak;
  }

  double calculateStrengthIndex(DateTime referenceDate) {
    double strength = 0.0;
    const double alphaGain = 0.065;
    const double betaDecay = 0.945;

    DateTime day = referenceDate.subtract(const Duration(days: 60));
    final end = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);

    while (!day.isAfter(end)) {
      if (isScheduledOn(day)) {
        if (isCompletedOn(day)) {
          strength = strength + alphaGain * (1.0 - strength);
        } else {
          strength = strength * betaDecay;
        }
      }
      day = day.add(const Duration(days: 1));
    }

    return (strength * 100.0).clamp(0.0, 100.0);
  }

  String get automaticityStage {
    final score = calculateStrengthIndex(DateTime.now());
    if (score < 25.0) return 'Forming';
    if (score < 50.0) return 'Building';
    if (score < 75.0) return 'Established';
    return 'Automatic';
  }

  double completionRate30Days(DateTime referenceDate) {
    int scheduled = 0;
    int completed = 0;

    DateTime day = referenceDate.subtract(const Duration(days: 29));
    final end = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);

    while (!day.isAfter(end)) {
      if (isScheduledOn(day)) {
        scheduled++;
        if (isCompletedOn(day)) {
          completed++;
        }
      }
      day = day.add(const Duration(days: 1));
    }

    if (scheduled == 0) return 0.0;
    return (completed / scheduled * 100.0);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'type': type.index,
        'frequency': frequency.index,
        'scheduledDays': scheduledDays,
        'targetValue': targetValue,
        'unit': unit,
        'createdAt': createdAt.toIso8601String(),
        'history': history.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? 'General',
        type: HabitType.values[(json['type'] as int?) ?? 0],
        frequency: HabitFrequency.values[(json['frequency'] as int?) ?? 0],
        scheduledDays: (json['scheduledDays'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [1, 2, 3, 4, 5, 6, 7],
        targetValue: (json['targetValue'] as num?)?.toDouble() ?? 1.0,
        unit: json['unit'] as String? ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        history: (json['history'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, DayEntry.fromJson(v as Map<String, dynamic>)),
            ) ??
            {},
      );
}
