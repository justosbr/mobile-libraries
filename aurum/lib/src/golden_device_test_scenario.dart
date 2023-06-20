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
    final width = children
        .map((child) => devices.map((e) => _getScenarioSize(_getDeviceSize(child, e)).width).reduce((pw, cw) => pw + cw))
        .reduce(max);
    final height = children
        .map((child) => devices.map((e) => _getScenarioSize(_getDeviceSize(child, e)).height).reduce(max))
        .reduce((ph, ch) => ph + ch);
    return Size(width, height);
  }

  Size _getDeviceSize(GoldenDeviceScenario child, Device device) {
    return child.orientation == Orientation.portrait ? device.size : device.size.flipped;
  }

  Size _getScenarioSize(Size size) {
    const horizontalPadding = _horizontalScenarioPadding * 2;
    const verticalPadding = _verticalScenarioPadding * 2;
    const border = _borderWidth * 2;

    return Size(size.width + horizontalPadding + border, size.height + verticalPadding + border);
  }
}

class GoldenDeviceScenario extends StatefulWidget {
  const GoldenDeviceScenario({
    super.key,
    required this.widget,
    this.name,
    this.setUp,
    this.devices,
    this.orientation = Orientation.portrait,
  });

  final ValueGetter<Widget> widget;
  final String? name;
  final SetUp? setUp;
  final List<Device>? devices;
  final Orientation orientation;

  @override
  State<GoldenDeviceScenario> createState() => _GoldenDeviceScenarioState();
}

class _GoldenDeviceScenarioState extends State<GoldenDeviceScenario> {
  Widget? _built;

  @override
  void initState() {
    super.initState();
    _setUp();
  }

  @override
  Widget build(BuildContext context) {
    if (_built == null) {
      return const SizedBox(
        width: 1,
        height: 1,
      );
    }

    final devices = widget.devices ??
        context.findAncestorWidgetOfExactType<GoldenDeviceGroupScenario>()?._overrideDevices ??
        context.findAncestorWidgetOfExactType<DeviceWrapper>()!.devices;

    return Row(
        children: devices
            .map((e) => _DeviceTestWidget(
                  device: e,
                  name: _createName(e),
                  orientation: widget.orientation,
                  child: _built!,
                ))
            .toList());
  }

  String _createName(Device device) {
    return widget.name == null ? device.name : '${widget.name} - ${device.name}';
  }

  void _setUp() async {
    await widget.setUp?.call();
    setState(() {
      _built = widget.widget();
    });
  }
}

class _DeviceTestWidget extends StatelessWidget {
  final String name;
  final Device device;
  final Widget child;
  final Orientation orientation;

  const _DeviceTestWidget({
    required this.device,
    required this.child,
    required this.name,
    required this.orientation,
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
                width: orientation == Orientation.portrait ? device.size.width : device.size.height,
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
              _DeviceMediaQueryWrapper(device: device, orientation: orientation, child: child),
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
    required this.child,
    required this.orientation,
  });

  final Device device;
  final Orientation orientation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.maybeOf(context) ?? const MediaQueryData();
    final deviceSize = orientation == Orientation.portrait ? device.size : device.size.flipped;
    final mergedMediaQuery = mediaQuery.copyWith(
      size: deviceSize,
      padding: orientation == Orientation.portrait
          ? device.safeArea
          : EdgeInsets.fromLTRB(
              device.safeArea.top,
              device.safeArea.right,
              device.safeArea.bottom,
              device.safeArea.left,
            ),
      platformBrightness: device.brightness,
      devicePixelRatio: device.devicePixelRatio,
      textScaleFactor: device.textScale,
    );

    return MediaQuery(
      data: mergedMediaQuery,
      child: SizedBox(
        width: deviceSize.width,
        height: deviceSize.height,
        child: child,
      ),
    );
  }
}
