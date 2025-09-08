import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService extends GetxService {
  late SharedPreferences _prefs;

  @override
  Future<void> onInit() async {
    super.onInit();
    _prefs = await SharedPreferences.getInstance();
  }

  /// Salvar string
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  /// Obter string
  Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }

  /// Salvar int
  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  /// Obter int
  Future<int?> getInt(String key) async {
    return _prefs.getInt(key);
  }

  /// Salvar bool
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  /// Obter bool
  Future<bool?> getBool(String key) async {
    return _prefs.getBool(key);
  }

  /// Salvar double
  Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  /// Obter double
  Future<double?> getDouble(String key) async {
    return _prefs.getDouble(key);
  }

  /// Salvar lista de strings
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  /// Obter lista de strings
  Future<List<String>?> getStringList(String key) async {
    return _prefs.getStringList(key);
  }

  /// Salvar objeto JSON
  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    return await setString(key, json.encode(value));
  }

  /// Obter objeto JSON
  Future<Map<String, dynamic>?> getJson(String key) async {
    final stringValue = await getString(key);
    if (stringValue == null) return null;
    
    try {
      return json.decode(stringValue) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Salvar lista de objetos JSON
  Future<bool> setJsonList(String key, List<Map<String, dynamic>> value) async {
    return await setString(key, json.encode(value));
  }

  /// Obter lista de objetos JSON
  Future<List<Map<String, dynamic>>?> getJsonList(String key) async {
    final stringValue = await getString(key);
    if (stringValue == null) return null;
    
    try {
      final List<dynamic> decodedList = json.decode(stringValue);
      return decodedList.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  /// Verificar se a chave existe
  Future<bool> containsKey(String key) async {
    return _prefs.containsKey(key);
  }

  /// Remover valor
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  /// Limpar todos os valores
  Future<bool> clear() async {
    return await _prefs.clear();
  }

  /// Obter todas as chaves
  Future<Set<String>> getAllKeys() async {
    return _prefs.getKeys();
  }

  /// Recarregar preferências
  Future<void> reload() async {
    await _prefs.reload();
  }
}