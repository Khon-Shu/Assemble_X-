import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Recommendation {
  final int id;
  final String modelName;
  final String category;
  final int price;
  final double similarityScore;
  final double compatibilityScore;
  final String brand;
  final String reason;
  final List<String> compatibilityNotes;
  final bool inDatabase;
  final String availabilityStatus;

  Recommendation({
    required this.id,
    required this.modelName,
    required this.category,
    required this.price,
    required this.similarityScore,
    required this.compatibilityScore,
    required this.brand,
    required this.reason,
    required this.compatibilityNotes,
    required this.inDatabase,
    required this.availabilityStatus,
  });

  int get scorePercentage {
    final score = compatibilityScore > 0 ? compatibilityScore : similarityScore;
    return (score * 100).round();
  }

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'] ?? 0,
      modelName: json['model_name'] ?? '',
      category: json['category'] ?? '',
      price: json['price'] ?? 0,
      similarityScore: (json['similarity_score'] ?? 0.0).toDouble(),
      compatibilityScore: (json['compatibility_score'] ?? 0.0).toDouble(),
      brand: json['brand'] ?? '',
      reason: json['reason'] ?? '',
      compatibilityNotes: List<String>.from(json['compatibility_notes'] ?? []),
      inDatabase: json['in_database'] ?? false,
      availabilityStatus: json['availability_status'] ?? 'Unknown',
    );
  }
}

class RecommendationService {
  // List of possible server URLs to try (auto-detection)
  static List<String> get baseUrls {
     return [
      "http://10.0.2.2:5000",    // Android Emulator
      "http://192.168.1.3:5000", // ← YOUR CORRECT IP
    ];
  }
  
  static String? _workingUrl;
  
  // Enhanced health check with auto-detection
  static Future<bool> isServerHealthy() async {
    print(' Checking recommendation server availability...');
    
    // Try each URL until one works
    for (String baseUrl in baseUrls) {
      print('Testing: $baseUrl');
      
      try {
        final response = await http
            .get(Uri.parse('$baseUrl/health'))
            .timeout(const Duration(seconds: 3));
        
        if (response.statusCode == 200) {
          print('Server found at: $baseUrl');
          _workingUrl = baseUrl;
          await _saveWorkingUrl(baseUrl);
          return true;
        }
      } catch (e) {
        print(' Failed: $baseUrl - $e');
        continue; // Try next URL
      }
    }
    
    // If none work, try the previously saved URL
    final savedUrl = await _getSavedUrl();
    if (savedUrl != null) {
      print(' Trying saved URL: $savedUrl');
      try {
        final response = await http
            .get(Uri.parse('$savedUrl/health'))
            .timeout(const Duration(seconds: 3));
        
        if (response.statusCode == 200) {
          print('Server found at saved URL: $savedUrl');
          _workingUrl = savedUrl;
          return true;
        }
      } catch (e) {
        print(' Saved URL also failed');
      }
    }
    
    print(' All server connections failed');
    return false;
  }

  static Future<String> get _currentBaseUrl async {
    if (_workingUrl != null) return _workingUrl!;
    
    // Try to get from shared preferences
    final savedUrl = await _getSavedUrl();
    if (savedUrl != null) {
      _workingUrl = savedUrl;
      return savedUrl;
    }
    
    // Fallback to first URL
    return baseUrls.first;
  }
  
  static Future<String?> _getSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('working_server_url');
  }
  
  static Future<void> _saveWorkingUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('working_server_url', url);
  }

  // Enhanced API methods with auto URL detection and STRICT MODE support
  static Future<List<Recommendation>> getSimilarRecommendations({
    required int componentId,
    required String category,
    int nRecommendations = 5,
    bool strict = false, // NEW: strict mode parameter
  }) async {
    try {
      final baseUrl = await _currentBaseUrl;
      print(' Getting similar recommendations from: $baseUrl (strict: $strict)');
      
      final response = await http.post(
        Uri.parse('$baseUrl/similar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'component_id': componentId,
          'category': category,
          'n_recommendations': nRecommendations,
          'strict': strict, // NEW: Send strict parameter
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final recommendations = List<Map<String, dynamic>>.from(data['recommendations'] ?? []);
          final availableCount = recommendations.where((r) => r['in_database'] == true).length;
          final strictMode = data['strict_mode'] ?? false;
          print('✅ Found ${recommendations.length} similar recommendations ($availableCount available in database, strict: $strictMode)');
          return recommendations.map((json) => Recommendation.fromJson(json)).toList();
        }
      } else {
        print(' Server error: ${response.statusCode}');
      }
      return [];
    } catch (e) {
      print(' Error getting similar recommendations: $e');
      return [];
    }
  }

  static Future<List<Recommendation>> getCompatibleRecommendations({
    required Map<String, int> currentBuild,
    required String targetCategory,
    int nRecommendations = 5,
    bool strict = false, // NEW: strict mode parameter
  }) async {
    try {
      final baseUrl = await _currentBaseUrl;
      print('🔄 Getting compatible recommendations from: $baseUrl (strict: $strict)');
      
      final response = await http.post(
        Uri.parse('$baseUrl/compatible'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'current_build': currentBuild,
          'target_category': targetCategory,
          'n_recommendations': nRecommendations,
          'strict': strict, // NEW: Send strict parameter
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Get separate lists for database and dataset
          final databaseRecs = List<Map<String, dynamic>>.from(data['database_recommendations'] ?? []);
          final datasetRecs = List<Map<String, dynamic>>.from(data['dataset_recommendations'] ?? []);
          
          final strictMode = data['strict_mode'] ?? false;
          print('✅ Found ${databaseRecs.length} database and ${datasetRecs.length} dataset compatible recommendations (strict: $strictMode)');
          
          // Return database recommendations first, then dataset
          final dbRecommendations = databaseRecs.map((json) => Recommendation.fromJson(json)).toList();
          final datasetRecommendations = datasetRecs.map((json) => Recommendation.fromJson(json)).toList();
          
          return dbRecommendations + datasetRecommendations;
        }
      } else {
        print(' Server error: ${response.statusCode}');
      }
      return [];
    } catch (e) {
      print(' Error getting compatible recommendations: $e');
      return [];
    }
  }

  // NEW: Get separate database and dataset recommendations
  static Future<Map<String, List<Recommendation>>> getCompatibleRecommendationsSeparate({
    required Map<String, int> currentBuild,
    required String targetCategory,
    int nRecommendations = 5,
  }) async {
    try {
      final baseUrl = await _currentBaseUrl;
      print('🔄 Getting separate compatible recommendations from: $baseUrl');
      
      final response = await http.post(
        Uri.parse('$baseUrl/compatible'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'current_build': currentBuild,
          'target_category': targetCategory,
          'n_recommendations': nRecommendations,
          'strict': false,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final databaseRecs = List<Map<String, dynamic>>.from(data['database_recommendations'] ?? []);
          final datasetRecs = List<Map<String, dynamic>>.from(data['dataset_recommendations'] ?? []);
          
          print('✅ Found ${databaseRecs.length} database and ${datasetRecs.length} dataset recommendations');
          
          return {
            'database': databaseRecs.map((json) => Recommendation.fromJson(json)).toList(),
            'dataset': datasetRecs.map((json) => Recommendation.fromJson(json)).toList(),
          };
        }
      }
      return {'database': [], 'dataset': []};
    } catch (e) {
      print('❌ Error getting separate compatible recommendations: $e');
      return {'database': [], 'dataset': []};
    }
  }

  static Future<void> debugRecommendations() async {
    print('🎯 DEBUG: Testing recommendation endpoints...');
    
    final baseUrl = await _currentBaseUrl;
    print('🎯 Using URL: $baseUrl');
    
    try {
      // Test similar endpoint with strict mode
      print('🔍 Testing /similar endpoint with strict=false...');
      final similarResponse = await http.post(
        Uri.parse('$baseUrl/similar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'component_id': 1,
          'category': 'cpu',
          'n_recommendations': 3,
          'strict': false, // Test non-strict mode
        }),
      ).timeout(const Duration(seconds: 5));
      
      print(' /similar status: ${similarResponse.statusCode}');
      if (similarResponse.statusCode == 200) {
        final data = json.decode(similarResponse.body);
        print(' /similar response (strict=false): ${data['recommendations']?.length ?? 0} items');
      }
      
      // Test similar endpoint with strict mode
      print('🔍 Testing /similar endpoint with strict=true...');
      final similarStrictResponse = await http.post(
        Uri.parse('$baseUrl/similar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'component_id': 1,
          'category': 'cpu',
          'n_recommendations': 3,
          'strict': true, // Test strict mode
        }),
      ).timeout(const Duration(seconds: 5));
      
      print(' /similar strict status: ${similarStrictResponse.statusCode}');
      if (similarStrictResponse.statusCode == 200) {
        final data = json.decode(similarStrictResponse.body);
        print(' /similar response (strict=true): ${data['recommendations']?.length ?? 0} items');
      }
      
      // Test compatible endpoint with strict mode
      print('🔍 Testing /compatible endpoint with strict=false...');
      final compatibleResponse = await http.post(
        Uri.parse('$baseUrl/compatible'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'current_build': {'cpu': 1},
          'target_category': 'motherboard',
          'n_recommendations': 3,
          'strict': false, // Test non-strict mode
        }),
      ).timeout(const Duration(seconds: 5));
      
      print('🎯 /compatible status: ${compatibleResponse.statusCode}');
      if (compatibleResponse.statusCode == 200) {
        final data = json.decode(compatibleResponse.body);
        print('🎯 /compatible response (strict=false): ${data['recommendations']?.length ?? 0} items');
      }
      
      // Test compatible endpoint with strict mode
      print('🔍 Testing /compatible endpoint with strict=true...');
      final compatibleStrictResponse = await http.post(
        Uri.parse('$baseUrl/compatible'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'current_build': {'cpu': 1},
          'target_category': 'motherboard',
          'n_recommendations': 3,
          'strict': true, // Test strict mode
        }),
      ).timeout(const Duration(seconds: 5));
      
      print('🎯 /compatible strict status: ${compatibleStrictResponse.statusCode}');
      if (compatibleStrictResponse.statusCode == 200) {
        final data = json.decode(compatibleStrictResponse.body);
        print('🎯 /compatible response (strict=true): ${data['recommendations']?.length ?? 0} items');
      }
      
    } catch (e) {
      print('❌ Debug test failed: $e');
    }
  }

  // Enhanced test method
  static Future<void> testConnection() async {
    print('🔍 Testing all possible connections...');
    final healthy = await isServerHealthy();
    
    if (healthy) {
      final currentUrl = await _currentBaseUrl;
      print('✅ Connected to: $currentUrl');
      
      // Test network info endpoint
      try {
        final response = await http.get(Uri.parse('$currentUrl/network'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('🌐 Network info: ${data['local_ips']}');
        }
      } catch (e) {
        print('⚠️ Network endpoint not available');
      }
    } else {
      print('❌ No server connection found');
      print('💡 Please check:');
      print('   • Flask server is running');
      print('   • Firewall allows port 5000');
      print('   • Phone and computer on same WiFi');
      print('   • Correct IP address in baseUrls list');
    }
  }

  // Method to manually set IP (for debugging)
  static Future<void> setManualIp(String ip) async {
    if (!ip.startsWith('http://')) {
      ip = 'http://$ip:5000';
    }
    _workingUrl = ip;
    await _saveWorkingUrl(ip);
    print('🔧 Manually set server URL to: $ip');
  }

  // NEW: Method to test strict vs non-strict modes
  static Future<void> testStrictMode() async {
    print('🧪 Testing Strict Mode vs Non-Strict Mode...');
    
    try {
      // Test non-strict mode (should return both database and dataset components)
      print('🔍 Testing NON-STRICT mode (should return mixed results)...');
      final nonStrictResults = await getCompatibleRecommendations(
        currentBuild: {'cpu': 1},
        targetCategory: 'ram',
        nRecommendations: 5,
        strict: false,
      );
      
      final nonStrictDbCount = nonStrictResults.where((r) => r.inDatabase).length;
      final nonStrictDatasetCount = nonStrictResults.where((r) => !r.inDatabase).length;
      print('📊 NON-STRICT Results: $nonStrictDbCount DB + $nonStrictDatasetCount Dataset = ${nonStrictResults.length} total');
      
      // Test strict mode (should return only database components)
      print('🔍 Testing STRICT mode (should return only database components)...');
      final strictResults = await getCompatibleRecommendations(
        currentBuild: {'cpu': 1},
        targetCategory: 'ram',
        nRecommendations: 5,
        strict: true,
      );
      
      final strictDbCount = strictResults.where((r) => r.inDatabase).length;
      final strictDatasetCount = strictResults.where((r) => !r.inDatabase).length;
      print('📊 STRICT Results: $strictDbCount DB + $strictDatasetCount Dataset = ${strictResults.length} total');
      
      print('✅ Strict mode test completed');
      
    } catch (e) {
      print('❌ Strict mode test failed: $e');
    }
  }
}