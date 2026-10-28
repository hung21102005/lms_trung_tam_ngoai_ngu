import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/shared/widgets/searchable_entity_field.dart';

void main() {
  testWidgets('Mobile mở bottom sheet khi chạm nhãn và tìm theo mã', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    String? selectedId;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SearchableEntityField(
              label: 'Học viên',
              options: const [
                EntityOption(
                  id: 'student-1',
                  label: 'Nguyễn Minh Anh (DEMO-HV-01)',
                ),
                EntityOption(
                  id: 'student-2',
                  label: 'Trần Gia Bảo (DEMO-HV-02)',
                ),
              ],
              onSelected: (id) => selectedId = id,
            ),
          ),
        ),
      ),
    );
    await tester.tapAt(tester.getCenter(find.text('Học viên')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'HV-02');
    await tester.pumpAndSettle();
    expect(find.text('Trần Gia Bảo (DEMO-HV-02)'), findsOneWidget);
    await tester.tap(find.text('Trần Gia Bảo (DEMO-HV-02)'));
    await tester.pumpAndSettle();
    expect(selectedId, 'student-2');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile hiển thị danh mục rỗng', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SearchableEntityField(
            label: 'Phòng học',
            options: [],
            onSelected: _ignoreSelection,
          ),
        ),
      ),
    );
    await tester.tapAt(tester.getCenter(find.text('Phòng học')));
    await tester.pumpAndSettle();
    expect(find.text('Không có mục phù hợp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile không tràn với tên lựa chọn dài', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: SearchableEntityField(
              label: 'Giáo viên',
              selectedId: 'teacher-1',
              options: [
                EntityOption(
                  id: 'teacher-1',
                  label: 'Giảng viên Nguyễn Thị Hoàng Anh rất dài (GV-0001)',
                ),
              ],
              onSelected: _ignoreSelection,
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

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

void _ignoreSelection(String? _) {}
