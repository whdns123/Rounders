class MCPConfig {
  static const String baseUrl = 'http://lapidarist.co.kr/roundus'; // MCP 서버 URL
  static const int port = 8080; // MCP 서버 포트
  static const String apiKey = ''; // MCP API 키 (필요한 경우)

  // MCP 연결 타임아웃 설정
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
