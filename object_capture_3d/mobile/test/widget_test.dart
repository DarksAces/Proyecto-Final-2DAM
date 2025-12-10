import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:object_capture_3d/main.dart';
import 'package:object_capture_3d/utils/constants.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that MaterialApp is present
    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Verify title is used (this might be in the AppBar of HomeScreen)
    // We try to find the text of the app name.
    // expect(find.text(AppConstants.appName), findsOneWidget); 
  });
}
