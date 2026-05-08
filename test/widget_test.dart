import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huom/features/pet/presentation/screens/create_pet_screen.dart';

void main() {
  group('CreatePetScreen', () {
    testWidgets('dado se monta la pantalla, muestra el título HUOM',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: CreatePetScreen()),
        ),
      );

      // Act / Assert
      expect(find.text('HUOM'), findsOneWidget);
      expect(find.text('Tu mascota virtual'), findsOneWidget);
      expect(find.text('🥚'), findsOneWidget);
    });

    testWidgets('dado nombre vacío, botón no dispara navegación',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: CreatePetScreen()),
        ),
      );

      // Act
      await tester.tap(find.text('¡Comenzar!'));
      await tester.pump();

      // Assert: se queda en la misma pantalla
      expect(find.text('HUOM'), findsOneWidget);
    });

    testWidgets('caso borde: maxLength=12 limita el TextField', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: CreatePetScreen()),
        ),
      );

      // Assert
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.maxLength, 12);
    });
  });
}
