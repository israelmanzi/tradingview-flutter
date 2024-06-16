import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    ApiService apiService = ApiService();

    try {
      var data = await apiService.fetchTradingViewData();
      await apiService.promptGptApi(data);
      return Future.value(true);
    } catch (e) {
      return Future.value(false);
    }
  });
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await initializeApp();
  FlutterNativeSplash.remove();

  runApp(const MyApp());
}

Future<void> initializeApp() async {
  ApiService apiService = ApiService();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? secretHash = prefs.getString('secret_hash');
  String? device = prefs.getString('device_name');

  if (device == null || secretHash == null) {
    final deviceInfo = await apiService.generateDeviceInfo();

    device = deviceInfo['device_name'];
    secretHash = deviceInfo['secret_hash'];

    await apiService.registerDevice(
        deviceInfo['device_name'], deviceInfo['secret_hash']);
  }

  String authToken = await apiService.authenticateDevice(device!, secretHash!);
  prefs.setString('secret_hash', secretHash);
  prefs.setString('device_name', device);
  await prefs.setString('auth_token', authToken);

  String authInfo = await apiService.getAuthenticationInfo();
  await prefs.setString('auth_info', authInfo);

  // Workmanager().initialize(callbackDispatcher);
  // Workmanager().registerPeriodicTask(
  //   'integrateTradingViewWithGpt',
  //   'integrateTradingViewWithGpt',
  //   frequency: const Duration(minutes: 28),
  // );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  static const String title = 'TradingView with GPT-4o API';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: title),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _deviceName = '';
  String _authInfo = '';

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? deviceName = prefs.getString('device_name');
    String? authInfo = prefs.getString('auth_info');

    setState(() {
      _deviceName = deviceName ?? 'Unknown device';
      _authInfo = authInfo ?? 'Not authorized!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Text('Authenticated as $_deviceName\n\n Auth Info: $_authInfo'),
      ),
    );
  }
}
