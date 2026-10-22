import 'package:english_mobile_app/core/models/assessment.dart';
import 'package:english_mobile_app/core/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:english_mobile_app/core/widgets/score_axis_card.dart';

void main() {
  DimensionScore score(RubricDimension dimension,
          {double? band = 6, double confidence = .8, bool acoustic = false}) =>
      DimensionScore(
        dimension: dimension,
        estimatedBand: band,
        confidence: confidence,
        feedbackVi: 'Feedback',
        evidenceSnippets: const ['Actual transcript evidence'],
        hasAcousticEvidence: acoustic,
      );

  test('text cannot establish pronunciation even when numeric score exists',
      () {
    final result = score(RubricDimension.pronunciation);
    expect(result.isAvailable, isFalse);
    expect(result.displayBand, 'N/A');
    expect(score(RubricDimension.pronunciation, acoustic: true).isAvailable,
        isTrue);
  });

  test('missing confidence or evidence never gets an assumed valid score', () {
    const unknown = DimensionScore(
      dimension: RubricDimension.grammar,
      estimatedBand: 6,
      feedbackVi: 'No evidence',
    );
    expect(unknown.confidence, 0);
    expect(unknown.isAvailable, isFalse);
    expect(unknown.displayBand, 'N/A');
  });

  test('invalid numeric bands and confidences are hidden', () {
    for (final band in [-1.0, 9.5, double.nan, double.infinity]) {
      expect(score(RubricDimension.grammar, band: band).isAvailable, isFalse);
    }
    for (final confidence in [0.0, -1.0, 1.1, double.nan]) {
      expect(score(RubricDimension.grammar, confidence: confidence).isAvailable,
          isFalse);
    }
  });

  test('overall requires all four valid matching dimensions', () {
    final dimensions = {
      for (final dimension in RubricDimension.values)
        dimension: score(dimension, acoustic: true),
    };
    AssessmentReport report() => AssessmentReport(
          id: 'report',
          sessionId: 'session',
          summaryVi: 'Summary',
          overallEstimatedBand: 6,
          dimensions: dimensions,
          createdAt: DateTime.utc(2026),
        );
    expect(report().overallEstimatedBand, 6);
    dimensions[RubricDimension.pronunciation] =
        score(RubricDimension.pronunciation);
    expect(report().overallEstimatedBand, isNull);
    dimensions.remove(RubricDimension.pronunciation);
    expect(report().overallEstimatedBand, isNull);
    dimensions[RubricDimension.pronunciation] = score(RubricDimension.grammar);
    expect(report().overallEstimatedBand, isNull);
  });

  testWidgets('score card remains readable and expandable at 320dp and 200%',
      (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ScoreAxisCard(
              score: score(RubricDimension.pronunciation),
            ),
          ),
        ),
      ),
    ));
    expect(find.text('N/A'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byType(ListTile));
    await tester.pump();
    expect(find.text('Chưa đủ bằng chứng để ước lượng điểm.'), findsOneWidget);
    expect(find.text('Actual transcript evidence'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
