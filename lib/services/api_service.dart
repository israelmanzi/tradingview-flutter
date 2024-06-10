import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String tradingViewApiUri =
      const String.fromEnvironment('TRADING_VIEW_API_URI');
  final String gptApiUri = 'http://localhost:5000/api/v1';

  Future<Map<String, dynamic>> fetchTradingViewData() async {
    final response = await http.get(Uri.parse(tradingViewApiUri));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<void> promptGptApi(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(gptApiUri),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to prompt GPT API!');
    }
  }

  void registerDevice(String deviceName, String secretHash) async {
    await http.post(
      Uri.parse('$gptApiUri/auth/register-device'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8'
      },
      body: json.encode({'device_name': deviceName, 'secret_hash': secretHash}),
    );
  }

  Future<String> authenticateDevice(
      String deviceName, String secretHash) async {
    final response = await http.post(
        Uri.parse('$gptApiUri/auth/generate-auth-token'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: json
            .encode({'device_name': deviceName, 'secret_hash': secretHash}));

    if (response.statusCode != 200) {
      throw Exception('Failed to authenticate device! Try again later!');
    }

    return json.decode(response.body)['token'];
  }

  Future<String> generateSecretDeviceHash() async {
    final response = await http.get(Uri.parse('$gptApiUri/auth/generate-hash'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        });
    if (response.statusCode != 200) {
      throw Exception('Failed to generate secret hash!');
    }

    return response.body;
  }

  Future<String> generateDeviceUID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    // final deviceInfo = await deviceInfoPlugin.deviceInfo;
    const String deviceName = 'device_1';

    prefs.setString('device_name', deviceName);

    return deviceName;
  }

  Future<String> getAuthenticationInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? authToken = prefs.getString('auth_token');

    if (authToken == null) throw Exception('Unauthorized!');

    final response = await http.get(Uri.parse('$gptApiUri/auth/get-auth-info'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $authToken'
        });

    if (response.statusCode != 200) throw Exception('Unauthorized!');

    return response.body;
  }
}
