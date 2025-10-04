import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_remote/remote.dart';
import 'package:object_finder/object_finder.dart';

import 'delegate.dart';

const _kApplication = "application";
const _kDailyNotifications = "daily_notifications";
const _kWeeklyNotifications = "weekly_notifications";
const _kThemes = "themes";
const _kSecrets = "secrets";
const kDefaultConfigName = "configs";

const kDefaultConfigPaths = {
  _kApplication,
  _kDailyNotifications,
  _kWeeklyNotifications,
  _kSecrets,
  _kThemes,
};

enum PlatformType {
  android,
  ios,
  web,
  fuchsia,
  macos,
  windows,
  linux,
  wasm,
  system,
}

enum EnvironmentType { live, test, system }

class Configs extends Remote<ConfigsDelegate> {
  Configs._();

  static Configs? _i;

  static Configs get i => _i ??= Configs._();

  // ---------------------------------------------------------------------------
  // INITIAL PART
  // ---------------------------------------------------------------------------

  String _defaultPath = _kApplication;
  EnvironmentType? _environment;
  PlatformType? _platform;

  EnvironmentType get environment {
    if (i._environment != null && i._environment != EnvironmentType.system) {
      return i._environment!;
    }
    if (kDebugMode) return EnvironmentType.test;
    if (kReleaseMode) return EnvironmentType.live;
    return EnvironmentType.system;
  }

  PlatformType get platform {
    if (i._platform != null && i._platform != PlatformType.system) {
      return i._platform!;
    }
    if (kIsWeb) return PlatformType.web;
    if (kIsWasm) return PlatformType.wasm;
    if (Platform.isAndroid) return PlatformType.android;
    if (Platform.isIOS) return PlatformType.ios;
    if (Platform.isFuchsia) return PlatformType.fuchsia;
    if (Platform.isMacOS) return PlatformType.macos;
    if (Platform.isWindows) return PlatformType.windows;
    if (Platform.isLinux) return PlatformType.linux;
    return PlatformType.system;
  }

  set environment(EnvironmentType type) {
    i._environment = type;
    i.notifyListeners();
  }

  set platform(PlatformType type) {
    i._platform = type;
    i.notifyListeners();
  }

  static Future<void> init({
    String? name,
    ConfigsDelegate? delegate,
    Set<String>? paths,
    Set<String>? symmetricPaths,
    bool connected = false,
    bool listening = true,
    bool showLogs = true,
    VoidCallback? onReady,
    String defaultPath = _kApplication,
    PlatformType platform = PlatformType.system,
    EnvironmentType environment = EnvironmentType.system,
  }) async {
    i._defaultPath = defaultPath;
    i._environment = environment;
    i._platform = platform;
    await i.initialize(
      name: name ?? kDefaultConfigName,
      connected: connected,
      delegate: delegate,
      paths: {...kDefaultConfigPaths, if (paths != null) ...paths},
      symmetricPaths: {
        _kApplication,
        if (symmetricPaths != null) ...symmetricPaths,
      },
      listening: listening,
      showLogs: showLogs,
      onReady: onReady,
    );
  }

  // ---------------------------------------------------------------------------
  // FINAL PART
  // ---------------------------------------------------------------------------

  (String, String) _keys(String key) {
    if (!key.contains("/")) return (_defaultPath, key);
    List<String> keys = key.split("/");
    if (keys.length < 2) return (_defaultPath, key);
    final k = keys.last;
    keys.removeLast();
    final p = keys.join("/");
    return (p, k);
  }

  Map _env(Map data, EnvironmentType? environment) {
    Map value = {};
    final x = data["default"];
    if (x is Map) value = value.combine(x);
    environment ??= this.environment;
    if (environment == EnvironmentType.system) environment = this.environment;
    final y = data[environment.name];
    if (y is Map) value = value.combine(y);
    return value;
  }

  Object? _pla(Map data, Object? base, PlatformType? platform) {
    platform ??= this.platform;
    if (platform == PlatformType.system) platform = this.platform;
    Object? value = data[platform.name];
    if (value != null) return value;
    if (base is Map) value = base[platform.name];
    return value ?? base;
  }

  Object? _select(
    String key, {
    String? path,
    EnvironmentType? environment,
    PlatformType? platform,
  }) {
    final keys = path == null ? _keys(key) : (path, key);
    final data = props[keys.$1];
    if (data is! Map) return null;
    final env = _env(data, environment);
    final x = env[keys.$2];
    if (x is! Map) return x;
    Object? mDefault = data['default'];
    if (mDefault is Map) mDefault = mDefault[keys.$2];
    final y = _pla(x, mDefault, platform);
    return y;
  }

  Object? _find(
    String name, {
    EnvironmentType? environment,
    PlatformType? platform,
  }) {
    final data = props[name];
    if (data is! Map) return null;
    final env = _env(data, environment);
    return env;
  }

  static T? load<T extends Object?>({
    String? name,
    T? defaultValue,
    EnvironmentType? environment,
    PlatformType? platform,
    T? Function(Object?)? parser,
    T? Function(T)? modifier,
  }) {
    try {
      final raw = i._find(
        name ?? _kThemes,
        environment: environment,
        platform: platform,
      );
      T? value = raw?.findOrNull(builder: parser);
      if (value is! T) return defaultValue;
      if (modifier != null) value = modifier(value);
      return value;
    } catch (msg) {
      i.log(msg);
      return defaultValue;
    }
  }

  static T get<T extends Object?>(
    String key, {
    String? path,
    T? defaultValue,
    EnvironmentType? environment,
    PlatformType? platform,
    T? Function(Object?)? parser,
    T? Function(T)? modifier,
  }) {
    T? value = getOrNull(
      key,
      path: path,
      defaultValue: defaultValue,
      environment: environment,
      platform: platform,
      parser: parser,
      modifier: modifier,
    );
    if (value != null) return value;
    throw UnimplementedError("$T didn't get from this ${i.name}");
  }

  static T? getOrNull<T extends Object?>(
    String key, {
    String? path,
    T? defaultValue,
    EnvironmentType? environment,
    PlatformType? platform,
    T? Function(Object?)? parser,
    T? Function(T)? modifier,
  }) {
    try {
      final raw = i._select(
        key,
        path: path,
        environment: environment,
        platform: platform,
      );
      T? value = raw?.findOrNull(builder: parser);
      if (value is! T) return defaultValue;
      if (modifier != null) value = modifier(value);
      return value;
    } catch (msg) {
      i.log(msg);
      return defaultValue;
    }
  }

  static List<T> gets<T extends Object?>(
    String key, {
    String? path,
    List<T>? defaultValue,
    EnvironmentType? environment,
    PlatformType? platform,
    T? Function(Object?)? parser,
    T? Function(T)? modifier,
  }) {
    List<T>? value = getsOrNull(
      key,
      path: path,
      defaultValue: defaultValue,
      environment: environment,
      platform: platform,
      parser: parser,
      modifier: modifier,
    );
    if (value != null) return value;
    throw UnimplementedError("${List<T>} didn't get from this ${i.name}");
  }

  static List<T>? getsOrNull<T extends Object?>(
    String key, {
    String? path,
    List<T>? defaultValue,
    EnvironmentType? environment,
    PlatformType? platform,
    T? Function(Object?)? parser,
    T? Function(T)? modifier,
  }) {
    try {
      final raw = i._select(
        key,
        path: path,
        environment: environment,
        platform: platform,
      );
      List<T>? value = raw.findsOrNull(builder: parser);
      value ??= defaultValue;
      if (modifier != null) {
        value = value?.map(modifier).whereType<T>().toList();
      }
      return value;
    } catch (msg) {
      i.log(msg);
      return defaultValue;
    }
  }
}

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
    T? newValue = _fetch;
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
