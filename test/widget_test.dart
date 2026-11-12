import 'package:flutter_test/flutter_test.dart';
import 'package:leadsystem/main.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('abre a tela inicial do LeadSystem', (tester) async {
    final state = buildTestState();
    addTearDown(state.dispose);
    await tester.pumpWidget(LeadSystemApp(state: state));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Olá! O que vamos preparar?'), findsOneWidget);
    expect(find.text('Categorias'), findsOneWidget);
    expect(find.text('SantiGrill - Churrasqueiras Práticas'), findsNothing);
    expect(
      find.bySemanticsLabel('SantiGrill - Churrasqueiras Práticas'),
      findsOneWidget,
    );
  });
}
