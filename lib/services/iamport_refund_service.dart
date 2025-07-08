import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/payment_config.dart';

class IamportRefundService {
  // 아임포트 설정
  static const String _baseUrl = 'https://api.iamport.kr';
  static String get _impKey => PaymentConfig.impKey;
  static String get _impSecret => PaymentConfig.impSecret;

  // 액세스 토큰 발급
  Future<String?> _getAccessToken() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users/getToken'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'imp_key': _impKey, 'imp_secret': _impSecret}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['code'] == 0) {
          return data['response']['access_token'];
        }
      }
      return null;
    } catch (e) {
      print('액세스 토큰 발급 실패: $e');
      return null;
    }
  }

  // 환불 처리
  Future<Map<String, dynamic>> processRefund({
    required String merchantUid, // 주문번호
    required String reason, // 환불 사유
    double? amount, // 부분 환불 금액 (null이면 전액 환불)
  }) async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return {'success': false, 'message': '아임포트 인증에 실패했습니다.'};
      }

      final Map<String, dynamic> requestBody = {
        'merchant_uid': merchantUid,
        'reason': reason,
      };

      if (amount != null) {
        requestBody['amount'] = amount.toInt();
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/payments/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['code'] == 0) {
          // 환불 성공
          final responseData = data['response'];
          return {
            'success': true,
            'message': '환불이 완료되었습니다.',
            'refundAmount': responseData['cancel_amount'],
            'refundReceipt': responseData['cancel_receipt_url'],
            'impUid': responseData['imp_uid'],
          };
        } else {
          // 환불 실패
          return {
            'success': false,
            'message': data['message'] ?? '환불 처리에 실패했습니다.',
          };
        }
      } else {
        return {
          'success': false,
          'message': '환불 요청이 실패했습니다. (HTTP ${response.statusCode})',
        };
      }
    } catch (e) {
      print('환불 처리 오류: $e');
      return {'success': false, 'message': '환불 처리 중 오류가 발생했습니다: $e'};
    }
  }

  // 결제 상세 조회 (환불 가능 여부 확인용)
  Future<Map<String, dynamic>> getPaymentDetails(String merchantUid) async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return {'success': false, 'message': '아임포트 인증에 실패했습니다.'};
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/payments/find/$merchantUid'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['code'] == 0) {
          final paymentData = data['response'];
          return {'success': true, 'data': paymentData};
        } else {
          return {
            'success': false,
            'message': data['message'] ?? '결제 정보 조회에 실패했습니다.',
          };
        }
      } else {
        return {'success': false, 'message': '결제 정보 조회 요청이 실패했습니다.'};
      }
    } catch (e) {
      print('결제 정보 조회 오류: $e');
      return {'success': false, 'message': '결제 정보 조회 중 오류가 발생했습니다: $e'};
    }
  }
}
