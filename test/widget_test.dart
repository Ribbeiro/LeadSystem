import 'package:flutter_test/flutter_test.dart';
import 'package:leadsystem/main.dart';

void main() {
  testWidgets('abre a tela inicial do LeadSystem', (tester) async {
    await tester.pumpWidget(const LeadSystemApp());
    await tester.pumpAndSettle();

    expect(find.text('SantiGrill'), findsOneWidget);
    expect(find.text('Olá! O que vamos preparar?'), findsOneWidget);
    expect(find.text('Categorias'), findsOneWidget);
  });
}
