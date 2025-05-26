import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../models/user_model.dart';
import '../models/coupon_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class ProductPaymentScreen extends StatefulWidget {
  final Product product;
  final UserModel user;
  final int quantity;

  const ProductPaymentScreen({
    Key? key,
    required this.product,
    required this.user,
    required this.quantity,
  }) : super(key: key);

  @override
  State<ProductPaymentScreen> createState() => _ProductPaymentScreenState();
}

class _ProductPaymentScreenState extends State<ProductPaymentScreen> {
  bool _isLoading = true;
  bool _isProcessing = false;
  List<CouponModel> _availableCoupons = [];
  CouponModel? _selectedCoupon;
  late FirestoreService _firestoreService;
  String? _orderId;
  int _finalAmount = 0;
  String _selectedPaymentMethod = 'toss'; // 기본값은 토스페이

  @override
  void initState() {
    super.initState();
    _firestoreService = Provider.of<FirestoreService>(context, listen: false);
    _finalAmount = widget.product.price * widget.quantity;
    _loadCoupons();
  }

  // 사용 가능한 쿠폰 목록 로드
  Future<void> _loadCoupons() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _availableCoupons =
          await _firestoreService.getAvailableCoupons(widget.user.id);

      // 금액 조건에 맞는 쿠폰만 필터링
      final totalPrice = widget.product.price * widget.quantity;
      _availableCoupons = _availableCoupons
          .where((coupon) => coupon.isApplicableTo(totalPrice))
          .toList();

      // 할인액이 큰 쿠폰 순으로 정렬
      _availableCoupons
          .sort((a, b) => b.discountAmount.compareTo(a.discountAmount));

      // 자동으로 최적의 쿠폰 선택
      if (_availableCoupons.isNotEmpty) {
        _selectCoupon(_availableCoupons.first);
      }
    } catch (e) {
      _showMessage('쿠폰 정보를 불러오는데 실패했습니다.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 쿠폰 선택 처리
  void _selectCoupon(CouponModel? coupon) {
    setState(() {
      _selectedCoupon = coupon;
      _calculateFinalAmount();
    });
  }

  // 최종 결제 금액 계산
  void _calculateFinalAmount() {
    int discount = _selectedCoupon?.discountAmount ?? 0;
    _finalAmount = (widget.product.price * widget.quantity) - discount;

    // 음수가 되지 않도록 함
    if (_finalAmount < 0) {
      _finalAmount = 0;
    }
  }

  // 주문 생성 및 결제 처리
  Future<void> _processPayment() async {
    if (_isProcessing) return;

    // 토스페이가 아닌 다른 결제수단을 선택한 경우
    if (_selectedPaymentMethod != 'toss') {
      String paymentMethodName = '';
      switch (_selectedPaymentMethod) {
        case 'kakao':
          paymentMethodName = '카카오페이';
          break;
        case 'naver':
          paymentMethodName = '네이버페이';
          break;
        case 'bank':
          paymentMethodName = '계좌이체';
          break;
      }
      _showMessage('$paymentMethodName은 현재 준비 중입니다. 토스페이를 이용해주세요.');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // 주문 생성 (실제 구현에서는 주문 모델 필요)
      _orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';

      if (_finalAmount > 0) {
        // 토스페이 결제 URL 생성
        final paymentUrl = _createTossPaymentUrl(
          orderId: _orderId!,
          orderName: '${widget.product.title} x ${widget.quantity}',
          amount: _finalAmount,
          customerName: widget.user.name,
        );

        // 외부 결제 페이지로 이동
        final canLaunch = await launchUrl(
          Uri.parse(paymentUrl),
          mode: LaunchMode.externalApplication,
        );

        if (!canLaunch) {
          _showMessage('결제 페이지를 열 수 없습니다.');
          return;
        }

        // 결제 성공 처리 (실제로는 웹훅으로 처리되어야 함)
        // 여기서는 데모를 위해 결제 시도 시 자동 성공으로 처리
        await _completePayment();
      } else {
        // 0원 결제인 경우 바로 완료 처리
        await _completePayment();
      }
    } catch (e) {
      _showMessage('결제 처리 중 오류가 발생했습니다: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // 토스페이 결제 URL 생성
  String _createTossPaymentUrl({
    required String orderId,
    required String orderName,
    required int amount,
    required String customerName,
  }) {
    // 토스페이 테스트 결제 URL (실제 구현 시 실제 키로 변경 필요)
    const clientKey = 'test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq';
    const successUrl = 'https://example.com/success';
    const failUrl = 'https://example.com/fail';

    return 'https://pay.toss.im/public/widget/v1/payment'
        '?clientKey=$clientKey'
        '&amount=$amount'
        '&orderId=$orderId'
        '&orderName=${Uri.encodeComponent(orderName)}'
        '&customerName=${Uri.encodeComponent(customerName)}'
        '&successUrl=$successUrl'
        '&failUrl=$failUrl';
  }

  // 결제 완료 처리 (실제 구현 시 웹훅으로 처리)
  Future<void> _completePayment() async {
    if (_orderId == null) return;

    try {
      // 결제 완료 처리 (실제 구현에서는 주문 상태 업데이트 등 필요)
      
      // 결제 성공 메시지 표시
      if (mounted) {
        _showMessage('상품 구매가 완료되었습니다!');

        // 이전 화면으로 돌아가기
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showMessage('결제 완료 처리 중 오류가 발생했습니다: $e');
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('결제하기'),
        backgroundColor: const Color(0xFF4A55A2),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상품 정보 요약
                  _buildProductSummary(),

                  const SizedBox(height: 24),

                  // 쿠폰 선택 섹션
                  _buildCouponSection(),

                  const SizedBox(height: 24),

                  // 결제수단 선택
                  _buildPaymentMethodSection(),

                  const SizedBox(height: 24),

                  // 결제 금액 표시
                  _buildPaymentSummary(),

                  const SizedBox(height: 32),

                  // 결제 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedPaymentMethod == 'toss'
                            ? const Color(0xFF4A55A2)
                            : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(_buildPaymentButtonText()),
                    ),
                  ),

                  if (_finalAmount > 0) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        _selectedPaymentMethod == 'toss'
                            ? '결제는 토스페이로 안전하게 처리됩니다.'
                            : '현재는 토스페이만 이용 가능합니다.',
                        style: TextStyle(
                          color: _selectedPaymentMethod == 'toss'
                              ? Colors.grey
                              : Colors.red.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
    );
  }  // 상품 정보 요약 위젯
  Widget _buildProductSummary() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '상품 정보',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상품 이미지
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: widget.product.imagePath.isNotEmpty
                      ? Image.asset(
                          widget.product.imagePath,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported,
                                  color: Colors.grey),
                            );
                          },
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported,
                              color: Colors.grey),
                        ),
                ),
                const SizedBox(width: 16),
                // 상품 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.product.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '수량: ${widget.quantity}개',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '단가: ${NumberFormat('#,###').format(widget.product.price)}원',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 쿠폰 선택 섹션 위젯
  Widget _buildCouponSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '쿠폰 적용',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_availableCoupons.isEmpty) ...[
              Center(
                child: Text(
                  '사용 가능한 쿠폰이 없습니다.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ] else ...[
              // 쿠폰 선택 드롭다운
              DropdownButtonFormField<CouponModel?>(
                decoration: const InputDecoration(
                  labelText: '쿠폰 선택',
                  border: OutlineInputBorder(),
                ),
                value: _selectedCoupon,
                items: [
                  const DropdownMenuItem<CouponModel?>(
                    value: null,
                    child: Text('쿠폰 적용 안함'),
                  ),
                  ..._availableCoupons.map((coupon) {
                    return DropdownMenuItem<CouponModel>(
                      value: coupon,
                      child: Text(
                          '${coupon.title} (${NumberFormat('#,###').format(coupon.discountAmount)}원 할인)'),
                    );
                  }).toList(),
                ],
                onChanged: (newValue) {
                  _selectCoupon(newValue);
                },
              ),
              if (_selectedCoupon != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.confirmation_number,
                          color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedCoupon!.title,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedCoupon!.description,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '유효기간: ${DateFormat('yyyy.MM.dd').format(_selectedCoupon!.validUntil)}까지',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }  // 결제수단 선택 위젯
  Widget _buildPaymentMethodSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '결제수단',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // 토스페이
            _buildPaymentMethodTile(
              value: 'toss',
              title: '토스페이',
              subtitle: '간편하고 안전한 결제',
              icon: Icons.account_balance_wallet,
              iconColor: Colors.blue,
              isEnabled: true,
            ),

            // 카카오페이
            _buildPaymentMethodTile(
              value: 'kakao',
              title: '카카오페이',
              subtitle: '카카오톡으로 간편결제',
              icon: Icons.chat_bubble,
              iconColor: Colors.yellow.shade700,
              isEnabled: false,
            ),

            // 네이버페이
            _buildPaymentMethodTile(
              value: 'naver',
              title: '네이버페이',
              subtitle: '네이버 간편결제',
              icon: Icons.payment,
              iconColor: Colors.green,
              isEnabled: false,
            ),

            // 계좌이체
            _buildPaymentMethodTile(
              value: 'bank',
              title: '계좌이체',
              subtitle: '은행 계좌로 직접 이체',
              icon: Icons.account_balance,
              iconColor: Colors.grey.shade700,
              isEnabled: false,
            ),

            const SizedBox(height: 12),

            // 안내 문구
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '※ 현재는 토스페이만 이용 가능합니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 결제수단 선택 타일 위젯
  Widget _buildPaymentMethodTile({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isEnabled,
  }) {
    final bool isSelected = _selectedPaymentMethod == value;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? const Color(0xFF4A55A2) : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? const Color(0xFF4A55A2).withOpacity(0.1)
            : (isEnabled ? Colors.white : Colors.grey.shade50),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _selectedPaymentMethod,
        onChanged: isEnabled
            ? (newValue) {
                setState(() {
                  _selectedPaymentMethod = newValue!;
                });
              }
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isEnabled
                    ? iconColor.withOpacity(0.1)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isEnabled ? iconColor : Colors.grey.shade400,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color:
                              isEnabled ? Colors.black : Colors.grey.shade500,
                        ),
                      ),
                      if (!isEnabled) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '준비 중',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isEnabled
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        activeColor: const Color(0xFF4A55A2),
      ),
    );
  }  // 결제 금액 요약 위젯
  Widget _buildPaymentSummary() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '결제 금액',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // 상품 가격
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('상품 가격 (${widget.quantity}개)'),
                Text('${NumberFormat('#,###').format(widget.product.price * widget.quantity)}원'),
              ],
            ),

            // 쿠폰 할인 금액
            if (_selectedCoupon != null) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '쿠폰 할인',
                    style: TextStyle(
                      color: Colors.red[700],
                    ),
                  ),
                  Text(
                    '-${NumberFormat('#,###').format(_selectedCoupon!.discountAmount)}원',
                    style: TextStyle(
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ],

            // 최종 결제 금액
            const SizedBox(height: 16),
            const Divider(thickness: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '최종 결제 금액',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${NumberFormat('#,###').format(_finalAmount)}원',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A55A2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildPaymentButtonText() {
    if (_finalAmount == 0) {
      return '무료 구매하기';
    } else if (_selectedPaymentMethod == 'toss') {
      return '결제하기';
    } else if (_selectedPaymentMethod == 'kakao') {
      return '카카오페이로 결제하기';
    } else if (_selectedPaymentMethod == 'naver') {
      return '네이버페이로 결제하기';
    } else if (_selectedPaymentMethod == 'bank') {
      return '계좌이체로 결제하기';
    } else {
      return '결제하기';
    }
  }
}