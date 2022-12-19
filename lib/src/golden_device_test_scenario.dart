import 'dart:math';

import 'package:aurum/aurum.dart';
import 'package:flutter/material.dart';

import 'golden_test_adapter.dart';
import 'utilities.dart';

const double _horizontalScenarioPadding = 8.0;
const double _verticalScenarioPadding = 12.0;
const double _borderWidth = 1.0;

/// DeviceBuilder builds [Device] size driven layout for its children
class GoldenDeviceGroupScenario extends StatelessWidget {
  /// Create scenarios rendered on multiple device sizes in a widget
  /// to take a golden snapshot of. Renders devices horizontally and scenarios
  /// vertically.
  ///
  /// [wrap] (optional) will wrap the scenario's widget in the tree.
  ///
  /// [bgColor] will change the background color of output .png file
  const GoldenDeviceGroupScenario({
    super.key,
    required this.children,
    List<Device>? devices,
  }) : _overrideDevices = devices;

  /// list of created DeviceScenarios for each device type
  final List<GoldenDeviceScenario> children;
  final List<Device>? _overrideDevices;

  @override
  Widget build(BuildContext context) {
    final devices = _overrideDevices ?? context.findAncestorWidgetOfExactType<DeviceWrapper>()!.devices;
    final requiredSize = _requiredWidgetSize(devices);
    return Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: requiredSize.width,
        height: requiredSize.height,
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Size _requiredWidgetSize(List<Device> devices) {
    final width = devices.map((e) => _getScenarioSize(e).width).reduce((pw, cw) => pw + cw);
    final height = devices.map((e) => _getScenarioSize(e).height).reduce(max) * children.length;
    return Size(width, height);
  }

  Size _getScenarioSize(Device device) {
    const horizontalPadding = _horizontalScenarioPadding * 2;
    const verticalPadding = _verticalScenarioPadding * 2;
    const border = _borderWidth * 2;

    return Size(device.size.width + horizontalPadding + border, device.size.height + verticalPadding + border);
  }
}

class GoldenDeviceScenario extends StatelessWidget {
  const GoldenDeviceScenario({
    super.key,
    required this.widget,
    this.name,
    this.setUp,
    this.devices,
  });

  final ValueGetter<Widget> widget;
  final String? name;
  final SetUp? setUp;
  final List<Device>? devices;

  @override
  Widget build(BuildContext context) {
    final devices = this.devices ??
        context.findAncestorWidgetOfExactType<GoldenDeviceGroupScenario>()?._overrideDevices ??
        context.findAncestorWidgetOfExactType<DeviceWrapper>()!.devices;

    final child = Row(
        children: devices
            .map((e) => _DeviceTestWidget(
                  device: e,
                  widget: widget,
                  name: _createName(e),
                ))
            .toList());

    return setUp != null ? SetUpWrapWidget(setUp: setUp!, child: child) : child;
  }

  String _createName(Device device) {
    return name == null ? device.name : '$name - ${device.name}';
  }
}

class _DeviceTestWidget extends StatelessWidget {
  final String name;
  final Device device;
  final ValueGetter<Widget> widget;

  const _DeviceTestWidget({
    required this.device,
    required this.widget,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _horizontalScenarioPadding),
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(
            width: 1,
            color: Colors.lightBlue,
          )),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 20,
                width: device.size.width,
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              _DeviceMediaQueryWrapper(device: device, widget: widget),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceMediaQueryWrapper extends StatelessWidget {
  const _DeviceMediaQueryWrapper({
    required this.device,
    required this.widget,
  });

  final Device device;
  final ValueGetter<Widget> widget;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context) ?? const MediaQueryData();
    final mergedMediaQuery = mediaQuery.copyWith(
      size: device.size,
      padding: device.safeArea,
      platformBrightness: device.brightness,
      devicePixelRatio: device.devicePixelRatio,
      textScaleFactor: device.textScale,
    );

    return MediaQuery(
      data: mergedMediaQuery,
      child: SizedBox(
        width: device.size.width,
        height: device.size.height,
        child: widget(),
      ),
    );
  }
}
