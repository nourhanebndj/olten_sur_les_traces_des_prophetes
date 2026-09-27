// Test de fumée basique pour l'application Olten.
//
// Il vérifie simplement que l'app démarre sans erreur et que
// l'écran de démarrage (SplashPage) s'affiche correctement.

import 'package:flutter_test/flutter_test.dart';

import 'package:olten_sur_les_traces_des_prophetes/app/app.dart';

void main() {
  testWidgets('OltenApp démarre et affiche le splash', (
    WidgetTester tester,
  ) async {
    // Construit l'app et déclenche un frame.
    await tester.pumpWidget(const OltenApp());

    // Vérifie que le bouton "Commencer" du splash est bien affiché.
    expect(find.text('Commencer'), findsOneWidget);

    // Vérifie que le nom de l'app apparaît à l'écran.
    expect(find.text('Olten'), findsOneWidget);
  });
}