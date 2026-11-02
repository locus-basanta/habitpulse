import 'package:flutter_test/flutter_test.dart';
import 'package:habit_pulse/main.dart';

void main() {
  testWidgets('HabitPulse smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HabitPulseApp());
    expect(find.text('HabitPulse'), findsOneWidget);
  });
}
