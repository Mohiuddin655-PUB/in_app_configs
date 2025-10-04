import 'package:flutter/material.dart';

import 'configs.dart';

/// A widget that rebuilds automatically when a configuration value changes.
///
/// Example:
/// ```dart
/// ConfigBuilder<String>(
///   id: "welcome_message",
///   builder: (context, message) => Text(message ?? "Welcome!"),
/// );
/// ```
class ConfigBuilder<T extends Object?> extends StatefulWidget {
  final String id;
  final String? name;
  final T? initial;
  final PlatformType? platform;
  final EnvironmentType? environment;
  final T? Function(Object?)? parser;
  final T? Function(T)? modifier;
  final Widget Function(BuildContext context, T? value) builder;

  const ConfigBuilder({
    super.key,
    required this.id,
    this.name,
    required this.builder,
    this.initial,
    this.platform,
    this.environment,
    this.parser,
    this.modifier,
  });

  @override
  State<ConfigBuilder<T>> createState() => _ConfigBuilderState<T>();
}

class _ConfigBuilderState<T extends Object?> extends State<ConfigBuilder<T>> {
  T? value;

  T? get _fetch {
    return Configs.getOrNull(
      widget.id,
      path: widget.name,
      platform: widget.platform,
      environment: widget.environment,
      parser: widget.parser,
      modifier: widget.modifier,
    );
  }

  void _listen() {
    final newValue = _fetch;
    if (value == newValue) return;
    setState(() => value = newValue);
  }

  @override
  void initState() {
    super.initState();
    value = _fetch;
    Configs.i.addListener(_listen);
  }

  @override
  void dispose() {
    Configs.i.removeListener(_listen);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, value ?? widget.initial);
  }
}
