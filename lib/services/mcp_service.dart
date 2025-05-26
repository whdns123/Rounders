import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/mcp_config.dart';

class MCPService {
  final String baseUrl = MCPConfig.baseUrl;
  final int port = MCPConfig.port;

  Future<bool> testConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl:$port/status'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(MCPConfig.connectionTimeout);

      return response.statusCode == 200;
    } catch (e) {
      print('MCP 연결 테스트 실패: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getServerStatus() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl:$port/api/status'),
            headers: {
              'Content-Type': 'application/json',
              if (MCPConfig.apiKey.isNotEmpty)
                'Authorization': 'Bearer ${MCPConfig.apiKey}',
            },
          )
          .timeout(MCPConfig.receiveTimeout);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('서버 상태 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('서버 상태 조회 오류: $e');
      rethrow;
    }
  }

  // 추가 MCP API 메서드들을 여기에 구현할 수 있습니다.
}
