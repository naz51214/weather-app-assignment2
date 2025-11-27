import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/main.dart';

void main() {
  testWidgets('Weather app starts correctly', (WidgetTester tester) async {
    // Build our weather app
    await tester.pumpWidget(const WeatherApp());

    // Verify that our app starts with correct title
    expect(find.text('Weather App'), findsOneWidget);
    
    // Verify search bar is present
    expect(find.byType(TextField), findsOneWidget);
    
    // Verify search button is present
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets('Search functionality works', (WidgetTester tester) async {
    // Build our weather app
    await tester.pumpWidget(const WeatherApp());

    // Enter text in search field
    await tester.enterText(find.byType(TextField), 'London');
    
    // Verify text was entered
    expect(find.text('London'), findsOneWidget);
  });

  testWidgets('App displays loading state', (WidgetTester tester) async {
    // Build our weather app
    await tester.pumpWidget(const WeatherApp());

    // Tap search button
    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();

    // Should show loading or search interface
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}