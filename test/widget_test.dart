import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huom/features/pet/presentation/screens/create_pet_screen.dart';

void main() {
  group('CreatePetScreen', () {
    testWidgets('dado se monta la pantalla, muestra título y selector',
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
      expect(find.text('ELIGE TU MASCOTA'), findsOneWidget);
      expect(find.text('NOMBRE'), findsOneWidget);
    });

    testWidgets('dado nada seleccionado, el botón ¡COMENZAR! está deshabilitado',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: CreatePetScreen()),
        ),
      );

      // Assert
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
      expect(find.text('¡COMENZAR!'), findsOneWidget);
    });

    testWidgets('caso borde: TextField está limitado a 12 caracteres',
        (tester) async {
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
