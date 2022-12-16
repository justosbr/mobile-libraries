import 'package:aurum/src/aurum_config.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'host_platform.dart';

/// {@template aurum_test_variant}
/// A [TestVariant] used to run both CI and platform golden tests with one
/// [testWidgets] function.
/// {@endtemplate}
@visibleForTesting
class AurumTestVariant extends TestVariant<GoldensConfig> {
  /// {@macro aurum_test_variant}
  AurumTestVariant({
    required AurumConfig config,
    required HostPlatform currentPlatform,
  })  : _config = config,
        _currentPlatform = currentPlatform;

  final AurumConfig _config;
  final HostPlatform _currentPlatform;

  /// The [GoldensConfig] to use for the current variant
  GoldensConfig get currentConfig => _currentConfig;
  late GoldensConfig _currentConfig;

  @override
  String describeValue(GoldensConfig value) => value.environmentName;

  @override
  Future<void> setUp(GoldensConfig value) async {
    _currentConfig = value;
  }

  @override
  Future<void> tearDown(
      GoldensConfig value,
      covariant AurumTestVariant? memento,
      ) async {
    imageCache.clear();
  }

  @override
  Iterable<GoldensConfig> get values {
    final platformConfig = _config.platformGoldensConfig;
    final runPlatformTest = platformConfig.enabled &&
        platformConfig.platforms.contains(_currentPlatform);

    final ciConfig = _config.ciGoldensConfig;
    final runCiTest = ciConfig.enabled;

    return {
      if (runPlatformTest) platformConfig,
      if (runCiTest) ciConfig,
    };
  }
}
