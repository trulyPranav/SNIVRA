import 'package:shared_preferences/shared_preferences.dart';

class SaloonStorage {
  static const _activeSaloonIdKey = 'snivra_active_saloon_id';

  Future<void> saveActiveSaloonId(String saloonId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeSaloonIdKey, saloonId);
  }

  Future<String?> readActiveSaloonId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeSaloonIdKey);
  }

  Future<void> clearActiveSaloonId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeSaloonIdKey);
  }
}