
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:studybuddy/app.dart';
import 'package:studybuddy/data/study_repository.dart';
import 'package:studybuddy/providers/study_provider.dart';

void main() {
  testWidgets('StudyBuddy app loads successfully',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => StudyProvider(StudyRepository()),
        child: const StudyBuddyApp(),
      ),
    );

    await tester.pump();

    expect(find.byType(StudyBuddyApp), findsOneWidget);
  });
}
