// This is a basic Flutter widget test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemon_go_map/widgets/custom_bottom_nav.dart';

void main() {
  testWidgets('CustomBottomNavBar selection test', (WidgetTester tester) async {
    // We need a variable to track the state change
    int selectedIndex = 0;

    // Use StatefulBuilder to allow the test to rebuild with new state
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const Placeholder(),
          bottomNavigationBar: StatefulBuilder(
            builder: (context, setState) {
              return CustomBottomNavBar(
                currentIndex: selectedIndex,
                onTap: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
              );
            },
          ),
        ),
      ),
    );

    // Verify initial state (Home selected)
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Social'), findsOneWidget);

    // Tap on Social
    await tester.tap(find.text('Social'));
    await tester.pumpAndSettle();

    expect(selectedIndex, 1);
  });
}
