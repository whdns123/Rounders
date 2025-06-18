import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meeting.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'booking_complete_screen.dart';
import 'refund_info_screen.dart';
import 'package:portone_flutter/iamport_payment.dart';
import 'package:portone_flutter/model/payment_data.dart';

class BookingPaymentScreen extends StatefulWidget {
  final Meeting meeting;

  const BookingPaymentScreen({super.key, required this.meeting});

  @override
  State<BookingPaymentScreen> createState() => _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends State<BookingPaymentScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedPaymentMethod = '';
  String _selectedCardCompany = '';
  bool _allAgreed = false;
  bool _personalInfoAgreed = false;
  bool _thirdPartyInfoAgreed = false;
  bool _paymentServiceAgreed = false;

  bool _isLoadingUserInfo = true;

  bool get _canProceed {
    return _nameController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _selectedPaymentMethod.isNotEmpty &&
        (_selectedPaymentMethod != '카드 결제' ||
            _selectedCardCompany.isNotEmpty) &&
        _personalInfoAgreed &&
        _thirdPartyInfoAgreed &&
        _paymentServiceAgreed;
  }

  void _updateAllAgreed(bool? value) {
    setState(() {
      _allAgreed = value ?? false;
      _personalInfoAgreed = _allAgreed;
      _thirdPartyInfoAgreed = _allAgreed;
      _paymentServiceAgreed = _allAgreed;
    });
  }

  void _updateIndividualAgreement() {
    setState(() {
      _allAgreed =
          _personalInfoAgreed && _thirdPartyInfoAgreed && _paymentServiceAgreed;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firestoreService = Provider.of<FirestoreService>(
        context,
        listen: false,
      );

      final currentUser = authService.currentUser;
      if (currentUser != null) {
        final userModel = await firestoreService.getUserById(currentUser.uid);

        if (userModel != null && mounted) {
          setState(() {
            _nameController.text = userModel.name;
            _phoneController.text = userModel.phone;
            _emailController.text = userModel.email;
            _isLoadingUserInfo = false;
          });
        } else {
          // 사용자 정보가 없는 경우 기본값으로 설정
          setState(() {
            _nameController.text = currentUser.displayName ?? '';
            _emailController.text = currentUser.email ?? '';
            _isLoadingUserInfo = false;
          });
        }
      } else {
        setState(() {
          _isLoadingUserInfo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUserInfo = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사용자 정보를 불러오는 중 오류가 발생했습니다: $e'),
            backgroundColor: const Color(0xFFF44336),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      '예약 및 결제',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // 균형을 위한 공간
                ],
              ),
            ),

            // Content
            Expanded(
              child: Column(
                children: [
                  // Meeting Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      height: 76,
                      child: Row(
                        children: [
                          // Meeting Image
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: const Color(0xFF2E2E2E),
                              ),
                              image:
                                  ((widget.meeting.coverImageUrl?.isNotEmpty ??
                                          false) ||
                                      (widget.meeting.imageUrl?.isNotEmpty ??
                                          false))
                                  ? DecorationImage(
                                      image: NetworkImage(
                                        (widget
                                                    .meeting
                                                    .coverImageUrl
                                                    ?.isNotEmpty ==
                                                true)
                                            ? widget.meeting.coverImageUrl!
                                            : widget.meeting.imageUrl!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: const Color(0xFF2E2E2E),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Meeting Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.meeting.title,
                                  style: const TextStyle(
                                    color: Color(0xFFEAEAEA),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 16),

                                // Location and Time
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Color(0xFFD6D6D6),
                                    ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Text(
                                        '${widget.meeting.location} • ${_formatDateTime(widget.meeting.scheduledDate)}',
                                        style: const TextStyle(
                                          color: Color(0xFFD6D6D6),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),

                                // Price
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.attach_money,
                                      size: 16,
                                      color: Color(0xFFD6D6D6),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${widget.meeting.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}원',
                                      style: const TextStyle(
                                        color: Color(0xFFD6D6D6),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Divider
                  Container(height: 8, color: const Color(0xFF2E2E2E)),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 신청자 정보
                          _buildSectionTitle('신청자 정보'),
                          const SizedBox(height: 16),
                          _buildTextField('이름', _nameController, '이름'),
                          const SizedBox(height: 12),
                          _buildTextField(
                            '연락처',
                            _phoneController,
                            '01012345678',
                          ),
                          const SizedBox(height: 12),
                          _buildTextField(
                            '이메일',
                            _emailController,
                            'name@mail.com',
                          ),
                          const SizedBox(height: 36),

                          // 결제 수단
                          _buildSectionTitle('결제 수단'),
                          const SizedBox(height: 16),
                          _buildPaymentMethods(),
                          const SizedBox(height: 36),

                          // 결제 금액
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '결제 금액',
                                style: TextStyle(
                                  color: Color(0xFFF5F5F5),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${widget.meeting.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}원',
                                style: const TextStyle(
                                  color: Color(0xFFF44336),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 36),

                          // 환불 규정 안내
                          _buildRefundPolicy(),
                          const SizedBox(height: 36),

                          // 예약 및 결제 동의
                          _buildAgreementSection(),
                          const SizedBox(height: 100), // 버튼 공간 확보
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _canProceed ? _processPayment : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canProceed
                        ? const Color(0xFFF44336)
                        : const Color(0xFFC2C2C2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '${widget.meeting.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}원 결제하기',
                    style: TextStyle(
                      color: _canProceed
                          ? const Color(0xFFF5F5F5)
                          : const Color(0xFF8C8C8C),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFF5F5F5),
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFEAEAEA),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF3C3C3C),
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(
              color: Color(0xFFEAEAEA),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFA0A0A0),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    final paymentMethods = [
      {'name': '네이버 페이', 'value': '네이버 페이'},
      {'name': '카카오 페이', 'value': '카카오 페이'},
      {'name': '토스 페이', 'value': '토스 페이'},
      {'name': '카드 결제', 'value': '카드 결제'},
    ];

    return Column(
      children: [
        ...paymentMethods
            .map(
              (method) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPaymentMethod = method['value']!;
                        });
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedPaymentMethod == method['value']
                                ? const Color(0xFFF44336)
                                : const Color(0xFF8C8C8C),
                            width: 1,
                          ),
                          color: _selectedPaymentMethod == method['value']
                              ? const Color(0xFFF44336)
                              : Colors.transparent,
                        ),
                        child: _selectedPaymentMethod == method['value']
                            ? const Center(
                                child: Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: Color(0xFFF5F5F5),
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      method['name']!,
                      style: const TextStyle(
                        color: Color(0xFFF5F5F5),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),

        // 카드사 선택 (카드 결제 선택시에만 표시)
        if (_selectedPaymentMethod == '카드 결제') ...[
          const SizedBox(height: 16),
          Container(
            height: 44,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF8C8C8C)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCardCompany.isEmpty
                    ? null
                    : _selectedCardCompany,
                hint: const Text(
                  '카드사 선택',
                  style: TextStyle(
                    color: Color(0xFFEAEAEA),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                isExpanded: true,
                dropdownColor: const Color(0xFF2E2E2E),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFFEAEAEA),
                ),
                items:
                    [
                      '국민은행',
                      '신한은행',
                      '우리은행',
                      '하나은행',
                      '삼성카드',
                      'KB카드',
                      '롯데카드',
                      '현대카드',
                    ].map((String company) {
                      return DropdownMenuItem<String>(
                        value: company,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            company,
                            style: const TextStyle(
                              color: Color(0xFFEAEAEA),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCardCompany = newValue ?? '';
                  });
                },
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRefundPolicy() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '환불 규정 안내',
              style: TextStyle(
                color: Color(0xFFF5F5F5),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RefundInfoScreen(meeting: widget.meeting),
                  ),
                );
              },
              icon: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFFD6D6D6),
              ),
            ),
          ],
        ),
        const Text(
          '결제 후 30분 경과 전: 전액 환불\n참가 신청 후 승인이 완료되지 않은 경우: 전액 환불\n참여 확정 모임의 진행일 기준 4일 전까지: 전액 환불\n참여 확정 모임의 진행일 기준 3일 전부터: 환불 불가\n모임 진행 당일에 신청한 경우: 환불 불가',
          style: TextStyle(
            color: Color(0xFFD6D6D6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAgreementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('예약 및 결제 동의'),
        const SizedBox(height: 16),

        // 전체 동의
        _buildAgreementItem(
          '전체동의하기',
          _allAgreed,
          _updateAllAgreed,
          isMain: true,
        ),
        const SizedBox(height: 4),

        // 개별 동의 항목들
        _buildAgreementItem('(필수) 개인정보 수집 • 이용 동의', _personalInfoAgreed, (
          value,
        ) {
          setState(() {
            _personalInfoAgreed = value ?? false;
            _updateIndividualAgreement();
          });
        }, hasArrow: true),
        _buildAgreementItem('(필수) 개인정보 제3자 정보 제공 동의', _thirdPartyInfoAgreed, (
          value,
        ) {
          setState(() {
            _thirdPartyInfoAgreed = value ?? false;
            _updateIndividualAgreement();
          });
        }, hasArrow: true),
        _buildAgreementItem('(필수) 결제대행 서비스 이용약관 동의', _paymentServiceAgreed, (
          value,
        ) {
          setState(() {
            _paymentServiceAgreed = value ?? false;
            _updateIndividualAgreement();
          });
        }, hasArrow: true),
      ],
    );
  }

  Widget _buildAgreementItem(
    String text,
    bool value,
    ValueChanged<bool?> onChanged, {
    bool isMain = false,
    bool hasArrow = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: value
                      ? const Color(0xFFF44336)
                      : const Color(0xFF8C8C8C),
                  width: 1,
                ),
                color: value ? const Color(0xFFF44336) : Colors.transparent,
              ),
              child: value
                  ? const Center(
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: Color(0xFFF5F5F5),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isMain
                    ? const Color(0xFFEAEAEA)
                    : const Color(0xFFD6D6D6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (hasArrow)
            IconButton(
              onPressed: () {
                // 약관 상세 페이지로 이동
              },
              icon: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFFD6D6D6),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final weekday = weekdays[dateTime.weekday % 7];

    return '${dateTime.month}.${dateTime.day}($weekday) ${dateTime.hour}시 ${dateTime.minute.toString().padLeft(2, '0')}분';
  }

  void _processPayment() {
    // 예약번호 생성
    final bookingNumber = 'BOOK-${DateTime.now().millisecondsSinceEpoch}';
    final merchantUid = 'merchant_${DateTime.now().millisecondsSinceEpoch}';

    // 포트원 결제 페이지로 이동
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IamportPayment(
          appBar: AppBar(
            title: const Text('포트원 결제'),
            backgroundColor: const Color(0xFF111111),
            foregroundColor: Colors.white,
          ),
          initialChild: Container(
            color: const Color(0xFF111111),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFF44336)),
                  SizedBox(height: 20),
                  Text(
                    '결제 페이지를 불러오는 중...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          /* [필수입력] 가맹점 식별코드 - 테스트용 */
          userCode: 'iamport',
          /* [필수입력] 결제 데이터 */
          data: PaymentData(
            pg: 'html5_inicis', // KG이니시스
            payMethod: _getPayMethod(), // 선택된 결제수단
            name: widget.meeting.title, // 모임명
            merchantUid: merchantUid, // 주문번호
            amount: widget.meeting.price.toInt(), // 결제금액
            buyerName: _nameController.text, // 구매자 이름
            buyerTel: _phoneController.text, // 구매자 연락처
            buyerEmail: _emailController.text, // 구매자 이메일
            buyerAddr: widget.meeting.location, // 구매자 주소
            buyerPostcode: '06018', // 구매자 우편번호
            appScheme: 'rounders', // 앱 스키마
          ),
          /* [필수입력] 콜백 함수 */
          callback: (Map<String, String> result) {
            _handlePaymentResult(result, bookingNumber);
          },
        ),
      ),
    );
  }

  String _getPayMethod() {
    switch (_selectedPaymentMethod) {
      case '네이버페이':
        return 'naverpay';
      case '카카오페이':
        return 'kakaopay';
      case '토스페이':
        return 'tosspay';
      case '카드 결제':
        return 'card';
      default:
        return 'card';
    }
  }

  void _handlePaymentResult(Map<String, String> result, String bookingNumber) {
    if (result['imp_success'] == 'true') {
      // 결제 성공
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BookingCompleteScreen(
            meeting: widget.meeting,
            bookingNumber: bookingNumber,
          ),
        ),
      );
    } else {
      // 결제 실패
      Navigator.pop(context);
      _showPaymentFailureDialog(result['error_msg'] ?? '결제에 실패했습니다.');
    }
  }

  void _showPaymentFailureDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E2E2E),
        title: const Text('결제 실패', style: TextStyle(color: Colors.white)),
        content: Text(
          errorMessage,
          style: const TextStyle(color: Color(0xFFD6D6D6)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인', style: TextStyle(color: Color(0xFFF44336))),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
