import 'package:flutter_test/flutter_test.dart';
import 'package:chess_engine_app/main.dart';

void main() {
  testWidgets('App renders ChessMatch title on launch', (WidgetTester tester) async {
    await tester.pumpWidget(const ChessEngineApp());
    expect(find.text('CHESSMATCH'), findsOneWidget);
  });
}
