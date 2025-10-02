import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class StorageService extends GetxService {
  static const _encryptionKeyName = 'hive_encryption_key';
  static const _boxName = 'secure_storage';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late Box<dynamic> _box;
  bool _isEncrypted = false;

  Future<StorageService> init() async {
    final encryptionKey = await _loadOrCreateEncryptionKey();

    _box = await Hive.openBox<dynamic>(
      _boxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    _isEncrypted = true;

    if (kDebugMode) {
      print('🔐 StorageService: Hive box opened with encryption');
    }

    return this;
  }

  bool get isEncrypted => _isEncrypted;

  void ensureEncrypted() {
    if (!_isEncrypted) {
      throw StateError('Secure storage is not encrypted');
    }
  }

  Future<Uint8List> _loadOrCreateEncryptionKey() async {
    final encodedKey = await _secureStorage.read(key: _encryptionKeyName);
    if (encodedKey != null) {
      return base64Url.decode(encodedKey);
    }

    final key = Hive.generateSecureKey();
    await _secureStorage.write(
      key: _encryptionKeyName,
      value: base64UrlEncode(key),
    );
    return key;
  }

  Future<void> _ensureInitialized() async {
    if (!_box.isOpen) {
      throw Exception('StorageService not initialized');
    }
  }

  Future<bool> setString(String key, String value) async {
    await _ensureInitialized();
    await _box.put(key, value);
    return true;
  }

  Future<String?> getString(String key) async {
    await _ensureInitialized();
    final value = _box.get(key);
    if (value is String) {
      return value;
    }
    return value?.toString();
  }

  Future<bool> setInt(String key, int value) async {
    await _ensureInitialized();
    await _box.put(key, value);
    return true;
  }

  Future<int?> getInt(String key) async {
    await _ensureInitialized();
    final value = _box.get(key);
    return value is int ? value : int.tryParse('$value');
  }

  Future<bool> setBool(String key, bool value) async {
    await _ensureInitialized();
    await _box.put(key, value);
    return true;
  }

  Future<bool?> getBool(String key) async {
    await _ensureInitialized();
    final value = _box.get(key);
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return null;
  }

  Future<bool> setDouble(String key, double value) async {
    await _ensureInitialized();
    await _box.put(key, value);
    return true;
  }

  Future<double?> getDouble(String key) async {
    await _ensureInitialized();
    final value = _box.get(key);
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  Future<bool> setStringList(String key, List<String> value) async {
    await _ensureInitialized();
    await _box.put(key, value);
    return true;
  }

  Future<List<String>?> getStringList(String key) async {
    await _ensureInitialized();
    final value = _box.get(key);
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }

  Future<bool> setJson(String key, Map<String, dynamic> value) async {
    return setString(key, json.encode(value));
  }

  Future<Map<String, dynamic>?> getJson(String key) async {
    final stringValue = await getString(key);
    if (stringValue == null) return null;
    try {
      return json.decode(stringValue) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> setJsonList(String key, List<Map<String, dynamic>> value) async {
    return setString(key, json.encode(value));
  }

  Future<List<Map<String, dynamic>>?> getJsonList(String key) async {
    final stringValue = await getString(key);
    if (stringValue == null) return null;
    try {
      final List<dynamic> decoded = json.decode(stringValue);
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  Future<bool> containsKey(String key) async {
    await _ensureInitialized();
    return _box.containsKey(key);
  }

  Future<bool> remove(String key) async {
    await _ensureInitialized();
    await _box.delete(key);
    return true;
  }

  Future<bool> clear() async {
    await _ensureInitialized();
    await _box.clear();
    return true;
  }

  Future<Set<String>> getAllKeys() async {
    await _ensureInitialized();
    return _box.keys.cast<String>().toSet();
  }

  Future<void> reload() async {
    await _ensureInitialized();
    await _box.compact();
  }
}
