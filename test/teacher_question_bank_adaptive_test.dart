import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/data/models/exam_model.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/domain/repositories/exams_repository.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/presentation/bloc/exams_bloc.dart';
import 'package:lms_trung_tam_ngoai_ngu/features/exams/presentation/screens/question_bank_list_screen.dart';

class _Repository extends Fake implements ExamsRepository {
  _Repository({this.empty = false, this.fail = false});

  final bool empty;
  final bool fail;
  final List<QuestionBankModel> created = [];

  @override
  Future<List<QuestionBankModel>> getQuestionBanks({
    String? language,
    String? level,
    String? search,
  }) async {
    if (fail) throw StateError('Lỗi tải ngân hàng');
    return [
      if (!empty)
        const QuestionBankModel(
          id: 'bank-1',
          title: 'Ngân hàng câu hỏi IELTS Reading với tên dài',
          description: 'Bài đọc học thuật theo nhiều chủ đề.',
          level: 'B2',
          questionCount: 12,
        ),
      ...created,
    ];
  }

  @override
  Future<QuestionBankModel> createQuestionBank({
    required String title,
    String? description,
    String? language,
    String? level,
  }) async {
    final bank = QuestionBankModel(
      id: 'bank-new',
      title: title,
      description: description,
      language: language,
      level: level,
    );
    created.add(bank);
    return bank;
  }
}

Widget _app(_Repository repository) => MaterialApp(
  home: BlocProvider(
    create: (_) => ExamsBloc(repository: repository),
    child: const QuestionBankListScreen(),
  ),
);

void main() {
  for (final width in [320.0, 375.0, 393.0, 430.0, 800.0, 1200.0]) {
    testWidgets('ngân hàng câu hỏi ở $width px', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(_app(_Repository()));
      await tester.pumpAndSettle();
      expect(find.textContaining('Ngân hàng câu hỏi IELTS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Mobile tạo ngân hàng và tải lại dữ liệu thật', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _Repository(empty: true);
    await tester.pumpWidget(_app(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo ngân hàng').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tên ngân hàng *'),
      'Từ vựng A1',
    );
    final sheetButton = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.widgetWithText(FilledButton, 'Tạo ngân hàng'),
    );
    await tester.ensureVisible(sheetButton);
    await tester.tap(sheetButton);
    await tester.pumpAndSettle();
    expect(repository.created.single.title, 'Từ vựng A1');
    expect(find.text('Từ vựng A1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile có empty và API error', (tester) async {
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(_Repository(empty: true)));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có ngân hàng câu hỏi'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(_app(_Repository(fail: true)));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Không tải được ngân hàng câu hỏi'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile bottom sheet không tràn khi bàn phím mở', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_app(_Repository(empty: true)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo ngân hàng').first);
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
