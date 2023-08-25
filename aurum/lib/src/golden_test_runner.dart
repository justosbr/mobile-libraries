import 'package:aurum/src/local_golden_file_comparator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'device.dart';
import 'golden_test_adapter.dart';
import 'interactions.dart';
import 'pumps.dart';

/// Default golden test adapter used to interface with Flutter's testing
/// framework.
GoldenTestAdapter defaultGoldenTestAdapter = const FlutterGoldenTestAdapter();
GoldenTestAdapter _goldenTestAdapter = defaultGoldenTestAdapter;

/// Golden test adapter used to interface with Flutter's test framework.
/// Overriding this makes it easier to unit-test Alchemist.
GoldenTestAdapter get goldenTestAdapter => _goldenTestAdapter;

set goldenTestAdapter(GoldenTestAdapter value) => _goldenTestAdapter = value;

/// {@template golden_test_runner}
/// A utility class for running an individual golden test.
/// {@endtemplate}
abstract class GoldenTestRunner {
  /// {@macro golden_test_runner}
  const GoldenTestRunner();

  /// Runs a single golden test expectation.
  Future<void> run({
    required WidgetTester tester,
    required Object goldenPath,
    required Widget widget,
    required ThemeData? globalConfigTheme,
    required ThemeData? variantConfigTheme,
    bool forceUpdate = false,
    bool obscureText = false,
    bool renderShadows = false,
    double textScaleFactor = 1.0,
    BoxConstraints constraints = const BoxConstraints(),
    PumpAction pumpBeforeTest = onlyPumpAndSettle,
    PumpWidget pumpWidget = onlyPumpWidget,
    Interaction? whilePerforming,
    double threshold,
    List<Device> devices = const [],
  });
}

/// {@template flutter_golden_test_runner}
/// A [GoldenTestRunner] which uses the Flutter test framework to execute
/// a golden test.
/// {@endtemplate}
class FlutterGoldenTestRunner extends GoldenTestRunner {
  /// {@macro flutter_golden_test_runner}
  const FlutterGoldenTestRunner() : super();

  @override
  Future<void> run({
    required WidgetTester tester,
    required Object goldenPath,
    required Widget widget,
    ThemeData? globalConfigTheme,
    ThemeData? variantConfigTheme,
    bool forceUpdate = false,
    bool obscureText = false,
    bool renderShadows = false,
    double textScaleFactor = 1.0,
    BoxConstraints constraints = const BoxConstraints(),
    PumpAction pumpBeforeTest = onlyPumpAndSettle,
    PumpWidget pumpWidget = onlyPumpWidget,
    Interaction? whilePerforming,
    double threshold = 0.00,
    List<Device> devices = const [],
  }) async {
    assert(
      goldenPath is String || goldenPath is Uri,
      'Golden path must be a String or Uri.',
    );

    _setUpComparator(threshold);
    final childKey = FlutterGoldenTestAdapter.childKey;

    final mementoDebugDisableShadows = debugDisableShadows;
    debugDisableShadows = !renderShadows;

    try {
      await goldenTestAdapter.pumpGoldenTest(
        tester: tester,
        textScaleFactor: textScaleFactor,
        constraints: constraints,
        obscureFont: obscureText,
        globalConfigTheme: globalConfigTheme,
        variantConfigTheme: variantConfigTheme,
        pumpBeforeTest: pumpBeforeTest,
        pumpWidget: pumpWidget,
        widget: widget,
        devices: devices,
      );

      AsyncCallback? cleanup;
      if (whilePerforming != null) {
        cleanup = await whilePerforming(tester);
      }

      final finder = find.byKey(childKey);

      final toMatch = obscureText
          ? goldenTestAdapter.getBlockedTextImage(
              finder: finder,
              tester: tester,
            )
          : finder;

      try {
        await goldenTestAdapter.withForceUpdateGoldenFiles(
          forceUpdate: forceUpdate,
          callback: goldenTestAdapter.goldenFileExpectation(toMatch, goldenPath),
        );
        await cleanup?.call();
      } on TestFailure {
        rethrow;
      }
    } finally {
      debugDisableShadows = mementoDebugDisableShadows;

      await tester.binding.setSurfaceSize(null);
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  }

  void _setUpComparator(double threshold) {
    if (goldenFileComparator is LocalFileComparator) {
      final testUrl = (goldenFileComparator as LocalFileComparator).basedir;

      // flutter_test's LocalFileComparator expects the test's URI to be passed
      // as an argument, but it only uses it to parse the baseDir in order to
      // obtain the directory where the golden tests will be placed.
      // As such, we use the default `testUrl`, which is only the `baseDir` and
      // append a generically named `test.dart` so that the `baseDir` is
      // properly extracted.
      goldenFileComparator = LocalGoldenFileComparator(Uri.parse('$testUrl/test.dart'), threshold);
    } else {
      throw Exception(
        'Expected `goldenFileComparator` to be of type `LocalFileComparator`, '
        'but it is of type `${goldenFileComparator.runtimeType}`',
      );
    }
  }
}
