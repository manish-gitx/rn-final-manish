import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/tester_constants.dart';

class TokenService {
  static const String _tokenKey = 'auth_token';
  static const String _isTesterKey = 'is_tester';
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;
  TokenService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> saveToken(String token, {bool isTester = false}) async {
    await init();

    if (isTester) {
      // For tester accounts, save the tester flag
      await _prefs!.setBool(_isTesterKey, true);
      debugPrint('[TokenService] Tester account marked');
    } else {
      await _prefs!.setString(_tokenKey, token);
      await _prefs!.setBool(_isTesterKey, false);
      debugPrint('[TokenService] Token saved successfully');
    }
  }

  Future<String?> getToken() async {
    await init();

    // Check if this is a tester account
    final isTester = _prefs?.getBool(_isTesterKey) ?? false;

    if (isTester) {
      debugPrint('[TokenService] Returning tester token');
      return TesterConstants.testerJwtToken;
    }

    final token = _prefs?.getString(_tokenKey);
    debugPrint(
      '[TokenService] Token retrieved: ${token != null ? 'exists' : 'null'}',
    );
    return token;
  }

  Future<void> deleteToken() async {
    await init();
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_isTesterKey);
    debugPrint('[TokenService] Token deleted');
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> isTesterAccount() async {
    await init();
    return _prefs?.getBool(_isTesterKey) ?? false;
  }
}
