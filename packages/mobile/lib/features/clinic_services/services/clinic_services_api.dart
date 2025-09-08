import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/clinic_service.dart';

class ClinicServicesApi {
  static const String baseUrl = 'https://api.singleclin.com'; // Replace with actual API URL
  
  static Future<List<ClinicService>> getClinicServices(String clinicId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/clinics/$clinicId/services'),
        headers: {
          'Content-Type': 'application/json',
          // Add authorization header if needed
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ClinicService.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load clinic services: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching clinic services: $e');
    }
  }

  static Future<bool> bookService({
    required String clinicId,
    required String serviceId,
    required String userId,
    required DateTime appointmentDate,
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/appointments'),
        headers: {
          'Content-Type': 'application/json',
          // Add authorization header if needed
          // 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'clinicId': clinicId,
          'serviceId': serviceId,
          'userId': userId,
          'appointmentDate': appointmentDate.toIso8601String(),
          'notes': notes,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to book service: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error booking service: $e');
    }
  }

  static Future<Map<String, dynamic>> getUserCredits(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/credits'),
        headers: {
          'Content-Type': 'application/json',
          // Add authorization header if needed
          // 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load user credits: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user credits: $e');
    }
  }

  static Future<bool> consumeCredits({
    required String userId,
    required String serviceId,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/$userId/credits/consume'),
        headers: {
          'Content-Type': 'application/json',
          // Add authorization header if needed
          // 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'serviceId': serviceId,
          'amount': amount,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to consume credits: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error consuming credits: $e');
    }
  }
}