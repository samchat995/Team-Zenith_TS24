import 'package:flutter_test/flutter_test.dart';
import 'package:neural_nexus/main.dart';

void main() {
  testWidgets('Neural Nexus splash screen renders title and tagline', (WidgetTester tester) async {
    await tester.pumpWidget(const NeuralNexusApp());
    await tester.pump(const Duration(milliseconds: 1500));
    expect(find.text('NEURAL NEXUS'), findsOneWidget);
    expect(find.text('Small Steps. Stronger Memories.'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
  });
}
