import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/shared/widgets/searchable_entity_field.dart';

void main() {
  testWidgets('opens existing records on tap and selects an ID', (
    tester,
  ) async {
    String? selectedId;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: SearchableEntityField(
              label: 'Học viên',
              options: const [
                EntityOption(
                  id: 'uuid-1',
                  label: 'Nguyễn Minh Anh (DEMO-HV-01)',
                ),
                EntityOption(id: 'uuid-2', label: 'Trần Gia Bảo (DEMO-HV-02)'),
              ],
              onSelected: (id) => selectedId = id,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(DropdownMenu<String>));
    await tester.pumpAndSettle();
    expect(find.text('Nguyễn Minh Anh (DEMO-HV-01)'), findsWidgets);
    expect(find.text('Trần Gia Bảo (DEMO-HV-02)'), findsWidgets);

    await tester.tap(find.text('Trần Gia Bảo (DEMO-HV-02)').last);
    await tester.pumpAndSettle();
    expect(selectedId, 'uuid-2');
  });

  testWidgets(
    'filters options by account code without requiring the exact name',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: SearchableEntityField(
                label: 'Giáo viên',
                options: const [
                  EntityOption(
                    id: 'teacher-1',
                    label: 'Nguyễn Văn Dũng (GV-0001)',
                  ),
                  EntityOption(
                    id: 'teacher-2',
                    label: 'Trần Thị Lan (GV-0002)',
                  ),
                ],
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DropdownMenu<String>));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'GV-0002');
      await tester.pumpAndSettle();
      expect(find.text('Trần Thị Lan (GV-0002)'), findsWidgets);
      expect(
        find.text('Nguyễn Văn Dũng (GV-0001)').hitTestable(),
        findsNothing,
      );
    },
  );
}
