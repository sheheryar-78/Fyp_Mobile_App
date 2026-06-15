import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Replace this with your Vercel deployment URL, e.g., "https://nexcall-backend.vercel.app/api"
  static const String defaultBaseUrl = "https://fypmobileapp-production.up.railway.app/api";
  
  static String get baseUrl => defaultBaseUrl;

  // Helper: Get JWT token from SharedPreferences
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Helper: Save token & user
  static Future<void> saveAuth(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(user));
  }

  // Helper: Clear auth (logout)
  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // Helper: Get user profile
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null) {
      return jsonDecode(userStr) as Map<String, dynamic>;
    }
    return null;
  }

  // Helper: Build headers
  static Future<Map<String, String>> _getHeaders({bool isMultipart = false}) async {
    final headers = <String, String>{};
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }
    final token = await getToken();
    if (token != null) {
      // Backend expects Authorization: tokenString
      headers['Authorization'] = token;
    }
    return headers;
  }

  // 1. SIGNUP
  static Future<http.Response> signup(String name, String email, String password) async {
    final url = Uri.parse("$baseUrl/auth/signup");
    final body = jsonEncode({
      'name': name,
      'email': email,
      'password': password,
    });
    return await http.post(url, headers: await _getHeaders(), body: body);
  }

  // 2. LOGIN
  static Future<http.Response> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/auth/login");
    final body = jsonEncode({
      'email': email,
      'password': password,
    });
    final res = await http.post(url, headers: await _getHeaders(), body: body);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await saveAuth(data['token'], data['user']);
    }
    return res;
  }

  // 3. RESET PASSWORD (UNAUTHENTICATED)
  static Future<http.Response> resetPassword(String email, String newPassword) async {
    final url = Uri.parse("$baseUrl/auth/reset-password");
    final body = jsonEncode({
      'email': email,
      'newPassword': newPassword,
    });
    return await http.post(url, headers: await _getHeaders(), body: body);
  }

  // 4. GET PROFILE
  static Future<http.Response> getProfile() async {
    final url = Uri.parse("$baseUrl/users/profile");
    return await http.get(url, headers: await _getHeaders());
  }

  // 5. UPDATE PROFILE
  static Future<http.Response> updateProfile(String name, String email) async {
    final url = Uri.parse("$baseUrl/users/profile");
    final body = jsonEncode({'name': name, 'email': email});
    return await http.put(url, headers: await _getHeaders(), body: body);
  }

  // 6. UPDATE PASSWORD (AUTHENTICATED)
  static Future<http.Response> updatePassword(String currentPassword, String newPassword) async {
    final url = Uri.parse("$baseUrl/users/password");
    final body = jsonEncode({
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    return await http.put(url, headers: await _getHeaders(), body: body);
  }

  // 7. DELETE ACCOUNT
  static Future<http.Response> deleteAccount() async {
    final url = Uri.parse("$baseUrl/users/account");
    return await http.delete(url, headers: await _getHeaders());
  }

  // 8. DASHBOARD STATS
  static Future<http.Response> getDashboardStats() async {
    final url = Uri.parse("$baseUrl/dashboard/stats");
    return await http.get(url, headers: await _getHeaders());
  }

  // 9. RECENT CALLS
  static Future<http.Response> getCalls() async {
    final url = Uri.parse("$baseUrl/calls");
    return await http.get(url, headers: await _getHeaders());
  }

  // 10. RATE CALL
  static Future<http.Response> rateCall(String callId, int rating) async {
    final url = Uri.parse("$baseUrl/calls/$callId/rate");
    final body = jsonEncode({'rating': rating});
    return await http.put(url, headers: await _getHeaders(), body: body);
  }

  // 11. WEEKLY CALL ANALYTICS CHART
  static Future<http.Response> getWeeklyCalls() async {
    final url = Uri.parse("$baseUrl/analytics/weekly-calls");
    return await http.get(url, headers: await _getHeaders());
  }

  // 12. GET AGENTS
  static Future<http.Response> getAgents() async {
    final url = Uri.parse("$baseUrl/agents");
    return await http.get(url, headers: await _getHeaders());
  }

  // 13. CREATE AGENT
  static Future<http.Response> createAgent(String name, String phoneNumber, List<String> documents) async {
    final url = Uri.parse("$baseUrl/agents");
    final body = jsonEncode({
      'name': name,
      'phoneNumber': phoneNumber,
      'documents': documents,
    });
    return await http.post(url, headers: await _getHeaders(), body: body);
  }

  // 14. UPDATE AGENT
  static Future<http.Response> updateAgent(String id, Map<String, dynamic> data) async {
    final url = Uri.parse("$baseUrl/agents/$id");
    final body = jsonEncode(data);
    return await http.put(url, headers: await _getHeaders(), body: body);
  }

  // 15. DELETE AGENT
  static Future<http.Response> deleteAgent(String id) async {
    final url = Uri.parse("$baseUrl/agents/$id");
    return await http.delete(url, headers: await _getHeaders());
  }

  // 16. GET DOCUMENTS
  static Future<http.Response> getDocuments() async {
    final url = Uri.parse("$baseUrl/documents");
    return await http.get(url, headers: await _getHeaders());
  }

  // 17. UPLOAD DOCUMENT (Multipart file)
  static Future<http.StreamedResponse> uploadDocument(String filePath, String fileName) async {
    final url = Uri.parse("$baseUrl/documents/upload");
    final request = http.MultipartRequest("POST", url);
    
    // Add auth token
    final token = await getToken();
    if (token != null) {
      request.headers['Authorization'] = token;
    }

    // Attach file bytes
    final file = await http.MultipartFile.fromPath(
      'file',
      filePath,
      filename: fileName,
    );
    request.files.add(file);

    return await request.send();
  }

  // 18. DELETE DOCUMENT
  static Future<http.Response> deleteDocument(String id) async {
    final url = Uri.parse("$baseUrl/documents/$id");
    return await http.delete(url, headers: await _getHeaders());
  }

  // 19. DOWNLOAD DOCUMENT
  static String getDownloadUrl(String id) {
    return "$baseUrl/documents/download/$id";
  }

  // 20. GET TWILIO CONFIG (PHONE NUMBER)
  static Future<http.Response> getTwilioConfig() async {
    final url = Uri.parse("$baseUrl/twilio/config");
    return await http.get(url, headers: await _getHeaders());
  }

  // 21. GET BILLING
  static Future<http.Response> getBilling() async {
    final url = Uri.parse("$baseUrl/billing");
    return await http.get(url, headers: await _getHeaders());
  }

  // 22. STRIPE CHECKOUT
  static Future<http.Response> createCheckoutSession(String planName, int priceAmount) async {
    final url = Uri.parse("$baseUrl/billing/checkout");
    final body = jsonEncode({
      'planName': planName,
      'priceAmount': priceAmount,
    });
    return await http.post(url, headers: await _getHeaders(), body: body);
  }

  // 23. VERIFY STRIPE PAYMENT
  static Future<http.Response> verifyPayment(String sessionId, String planName) async {
    final url = Uri.parse("$baseUrl/billing/verify");
    final body = jsonEncode({
      'sessionId': sessionId,
      'planName': planName,
    });
    return await http.post(url, headers: await _getHeaders(), body: body);
  }
}
