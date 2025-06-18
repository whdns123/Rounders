import 'package:flutter/material.dart';
import '../services/license_service.dart';
import '../models/license_model.dart';
import 'license_detail_screen.dart';

class LicenseListScreen extends StatelessWidget {
  const LicenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final licenses = LicenseService.getLicenses();

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '오픈소스 라이선스',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '총 ${LicenseService.getTotalLicenseCount()}개의 오픈소스 라이브러리',
                  style: const TextStyle(
                    color: Color(0xFFC2C2C2),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '본 앱에서 사용된 오픈소스 라이브러리들의 라이선스 정보입니다.',
                  style: TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ],
            ),
          ),

          // License List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: licenses.length,
              itemBuilder: (context, index) {
                final license = licenses[index];
                return _buildLicenseItem(context, license);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseItem(BuildContext context, LicenseModel license) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LicenseDetailScreen(license: license),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E2E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Library Name and Version
              Row(
                children: [
                  Expanded(
                    child: Text(
                      license.name,
                      style: const TextStyle(
                        color: Color(0xFFEAEAEA),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                  Text(
                    'v${license.version}',
                    style: const TextStyle(
                      color: Color(0xFF8C8C8C),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF8C8C8C),
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                license.description,
                style: const TextStyle(
                  color: Color(0xFFC2C2C2),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // License Type
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        ),
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
}
