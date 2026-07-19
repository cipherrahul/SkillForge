import 'package:flutter_test/flutter_test.dart';
import 'package:skillforge_student/main.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SkillForgeApp());
    expect(find.text('SkillForge'), findsAny);
  });
}
