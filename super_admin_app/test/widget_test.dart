import 'package:flutter_test/flutter_test.dart';
import 'package:super_admin_app/main.dart';

void main() {
  testWidgets('app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const SuperAdminApp());
    expect(find.byType(SuperAdminApp), findsOneWidget);
  });
}
