import 'package:flutter_test/flutter_test.dart';
import 'package:healthtech_app/main.dart';

void main() {
  testWidgets('App launches and shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const HealthTechApp());
    expect(find.text('Good morning, Aarav'), findsOneWidget);
  });
}
