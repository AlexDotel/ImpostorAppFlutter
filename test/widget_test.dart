import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impostor/main.dart';
import 'package:impostor/word_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'firstRunGuideSeen': true});
  });

  test('the game contains 700 unique words and hints', () {
    expect(wordBank, hasLength(14));
    final words = wordBank.values.expand((category) => category.keys).toList();
    final hints = wordBank.values
        .expand((category) => category.values)
        .toList();
    expect(words, hasLength(700));
    expect(words.map((word) => word.toLowerCase()).toSet(), hasLength(700));
    expect(hints.every((hint) => hint.trim().isNotEmpty), isTrue);
    expect(hints.map((hint) => hint.toLowerCase()).toSet(), hasLength(700));
  });

  testWidgets('starts directly on the named reveal card', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const UndercoverApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jugar ahora'));
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
    }
    await tester.tap(find.text('Repartir roles'));
    await tester.pumpAndSettle();

    expect(find.text('Soy yo'), findsNothing);
    expect(find.text('Turno de'), findsOneWidget);
    expect(find.text('Jugador 1'), findsOneWidget);
    expect(find.text('DESLIZA Y MANTÉN'), findsOneWidget);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('reveal-cover'))),
    );
    await gesture.moveBy(const Offset(0, -150));
    await tester.pump();
    expect(find.text('Suelta para volver a ocultar'), findsOneWidget);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('La palabra está debajo'), findsOneWidget);
    expect(find.text('Pasar al siguiente'), findsOneWidget);
    final cover = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('reveal-cover')),
    );
    expect(cover.transform?.getTranslation().y, 0);
  });
}
