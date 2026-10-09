import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luxestay/screens/customer/explore_screen.dart';

void main() {
  testWidgets('quick category filters select and clear a single category', (
    tester,
  ) async {
    var selectedCategory = 'Tất cả';

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: ExploreQuickCategoryFilters(
                selectedCategory: selectedCategory,
                onChanged: (category) {
                  setState(() => selectedCategory = category);
                },
              ),
            );
          },
        ),
      ),
    );

    expect(_chip(tester, 'Tất cả').selected, isTrue);
    expect(_chip(tester, 'Resort ven biển').selected, isFalse);
    expect(_chip(tester, 'Villa riêng tư').selected, isFalse);

    await tester.tap(find.widgetWithText(FilterChip, 'Resort ven biển'));
    await tester.pump();

    expect(selectedCategory, 'Resort');
    expect(_chip(tester, 'Resort ven biển').selected, isTrue);
    expect(_chip(tester, 'Tất cả').selected, isFalse);

    await tester.tap(find.widgetWithText(FilterChip, 'Villa riêng tư'));
    await tester.pump();

    expect(selectedCategory, 'Villa');
    expect(_chip(tester, 'Villa riêng tư').selected, isTrue);
    expect(_chip(tester, 'Resort ven biển').selected, isFalse);

    await tester.tap(find.widgetWithText(FilterChip, 'Villa riêng tư'));
    await tester.pump();

    expect(selectedCategory, 'Tất cả');
    expect(_chip(tester, 'Tất cả').selected, isTrue);
  });
}

FilterChip _chip(WidgetTester tester, String label) {
  return tester.widget<FilterChip>(find.widgetWithText(FilterChip, label));
}
