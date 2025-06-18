import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/license_model.dart';

class LicenseDetailScreen extends StatelessWidget {
  final LicenseModel license;

  const LicenseDetailScreen({super.key, required this.license});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          license.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white),
            onPressed: () => _copyLicenseText(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Library Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2E2E2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          license.name,
                          style: const TextStyle(
                            color: Color(0xFFEAEAEA),
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getLicenseTypeColor(license.licenseType),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          license.licenseType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version ${license.version}',
                    style: const TextStyle(
                      color: Color(0xFF8C8C8C),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    license.description,
                    style: const TextStyle(
                      color: Color(0xFFC2C2C2),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard',
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Links Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2E2E2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '링크',
                    style: TextStyle(
                      color: Color(0xFFEAEAEA),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLinkItem('홈페이지', license.homepage),
                  const SizedBox(height: 8),
                  _buildLinkItem('저장소', license.repository),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // License Text Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2E2E2E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '라이선스 전문',
                          style: TextStyle(
                            color: Color(0xFFEAEAEA),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.copy,
                          color: Color(0xFF8C8C8C),
                          size: 20,
                        ),
                        onPressed: () => _copyLicenseText(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      license.licenseText,
                      style: const TextStyle(
                        color: Color(0xFFC2C2C2),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkItem(String title, String url) {
    return InkWell(
      onTap: () => _launchUrl(url),
      child: Row(
        children: [
          Icon(
            title == '홈페이지' ? Icons.language : Icons.code,
            color: const Color(0xFF8C8C8C),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFC2C2C2),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  url,
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.open_in_new, color: Color(0xFF8C8C8C), size: 16),
        ],
      ),
    );
  }

  Color _getLicenseTypeColor(String licenseType) {
    switch (licenseType) {
      case 'MIT License':
        return const Color(0xFF4CAF50);
      case 'BSD 3-Clause License':
        return const Color(0xFF2196F3);
      case 'Apache License 2.0':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF8C8C8C);
    }
  }

  void _copyLicenseText(BuildContext context) {
    Clipboard.setData(ClipboardData(text: license.licenseText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('라이선스 텍스트가 클립보드에 복사되었습니다.'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
