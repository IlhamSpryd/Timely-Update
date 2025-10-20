import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:timely/services/auth_services.dart';
import 'package:timely/models/device_token.dart';
import 'package:timely/api/endpoint.dart';

class DeviceApi {
  final AuthService _authService = AuthService();

  Future<DeviceTokenModel> updateDeviceToken(String playerId) async {
    final token = await _authService.getToken();

    final response = await http.post(
      Uri.parse(Endpoint.deviceToken),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"player_id": playerId}),
    );

    if (response.statusCode == 200) {
      return deviceTokenModelFromJson(response.body);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Failed to update device token.');
    }
  }
}
