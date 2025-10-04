import 'package:flutter/material.dart';
import 'package:in_app_configs/configs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Configs before the app starts
  await Configs.init(
    environment: EnvironmentType.test,
    // test / live / system
    platform: PlatformType.system,
    // or force specific platform
    paths: {
      "configs/application",
      "configs/themes",
    },
    showLogs: true,
    onReady: () => debugPrint("✅ Configs initialized successfully."),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiUrl = Configs.getOrNull<String>(
      "api_url",
      defaultValue: "https://fallback.example.com",
    );

    final themeColor = Configs.getOrNull<String>(
      "theme_color",
      defaultValue: "blue",
    );

    return MaterialApp(
      title: "Configs Demo",
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: themeColor == "orange" ? Colors.orange : Colors.blue,
        ),
      ),
      home: HomeScreen(apiUrl: apiUrl ?? ""),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final String apiUrl;

  const HomeScreen({super.key, required this.apiUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configs Example")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("API URL: $apiUrl"),
            const SizedBox(height: 16),

            /// Dynamically rebuilds if Configs updates
            ConfigBuilder<String>(
              id: "welcome_text",
              builder: (context, value) => Text(
                value ?? "Welcome!",
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
