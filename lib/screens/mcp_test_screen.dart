import 'package:flutter/material.dart';
import '../services/mcp_service.dart';

class MCPTestScreen extends StatefulWidget {
  const MCPTestScreen({super.key});

  @override
  State<MCPTestScreen> createState() => _MCPTestScreenState();
}

class _MCPTestScreenState extends State<MCPTestScreen> {
  final MCPService _mcpService = MCPService();
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '연결 테스트 중...';
    });

    try {
      final isConnected = await _mcpService.testConnection();
      setState(() {
        _statusMessage = isConnected ? 'MCP 연결 성공!' : 'MCP 연결 실패';
      });

      if (isConnected) {
        final status = await _mcpService.getServerStatus();
        setState(() {
          _statusMessage += '\n서버 상태: ${status.toString()}';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '오류 발생: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MCP 연결 테스트'),
        backgroundColor: Colors.indigo,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _testConnection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('MCP 연결 테스트'),
                ),
              const SizedBox(height: 24),
              if (_statusMessage.isNotEmpty)
                Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
