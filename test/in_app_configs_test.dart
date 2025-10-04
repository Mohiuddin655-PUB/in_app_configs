import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_configs/in_app_configs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Configs Tests', () {
    setUpAll(() async {
      await Configs.init(
        environment: EnvironmentType.test,
        platform: PlatformType.android,
        showLogs: false,
      );
    });

    test('Environment should be test in debug mode', () {
      expect(Configs.i.environment, EnvironmentType.test);
    });

    test('Platform detection works', () {
      expect(Configs.i.platform, isNot(PlatformType.system));
    });

    test('Can safely get default value', () {
      final result = Configs.getOrNull<String>(
        "theme_color",
        defaultValue: "blue",
      );
      expect(result, "blue");
    });
  });
}
