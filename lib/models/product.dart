import 'package:flutter/material.dart';

enum ProductCategory { game, goods, clothes, all }

class Product {
  final String id;
  final String title;
  final String imagePath;
  final int price;
  final int? originalPrice;
  final int discountRate;
  final ProductCategory category;
  final String description;
  final Map<String, String> shippingInfo;

  Product({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.price,
    this.originalPrice,
    this.discountRate = 0,
    required this.category,
    required this.description,
    required this.shippingInfo,
  });

  // 더미 데이터 생성 메서드
  static List<Product> getDummyProducts() {
    return [
      Product(
        id: '1',
        title: '라운더스 하나 빼기 키트',
        imagePath: 'assets/images/game_kit2.jpg',
        originalPrice: 28000,
        price: 28000,
        discountRate: 0,
        category: ProductCategory.game,
        description: '라운더스 하나 빼기 키트입니다. ',
        shippingInfo: {
          '배송': '택배 배송',
          '결제 후': '1-2일 내 출고',
          '배송비': '3,000원 (30,000원 이상 구매 시 무료)',
        },
      ),
      Product(
        id: '2',
        title: '라운더스 수식 하이 로우 키트',
        imagePath: 'assets/images/game_kit1.jpg',
        originalPrice: 28000,
        price: 28000,
        discountRate: 0,
        category: ProductCategory.game,
        description:
            '라운더스 게임킷3 상품입니다. 업그레이드된 컴포넌트와 새로운 게임 규칙이 포함되었습니다. 더욱 향상된 게임 경험을 즐겨보세요.',
        shippingInfo: {
          '배송': '택배 배송',
          '결제 후': '1-2일 내 출고',
          '배송비': '3,000원 (30,000원 이상 구매 시 무료)',
        },
      ),
      Product(
        id: '3',
        title: '라운더스 노트',
        imagePath: 'assets/images/notebook.png',
        originalPrice: 7500,
        price: 7125,
        discountRate: 5,
        category: ProductCategory.goods,
        description:
            '라운더스 노트북입니다. 고급스러운 디자인과 내구성 있는 커버가 특징입니다. 게임 기록과 전략 수립에 최적화되어 있습니다.',
        shippingInfo: {
          '배송': '택배 배송',
          '결제 후': '1-2일 내 출고',
          '배송비': '2,500원 (20,000원 이상 구매 시 무료)',
        },
      ),
      Product(
        id: '4',
        title: '라운더스 제비뽑기 키트',
        imagePath: 'assets/images/game_kit3.png',
        originalPrice: 35000,
        price: 35000,
        discountRate: 0,
        category: ProductCategory.goods,
        description: '라운더스 제비뽑기 키트입니다. ',
        shippingInfo: {
          '배송': '택배 배송',
          '결제 후': '1-2일 내 출고',
          '배송비': '2,500원 (20,000원 이상 구매 시 무료)',
        },
      ),
      Product(
        id: '5',
        title: '언노운',
        imagePath: 'assets/images/unknown.png',
        originalPrice: 65000,
        price: 65000,
        discountRate: 0,
        category: ProductCategory.goods,
        description: '언노운 키트입니다. ',
        shippingInfo: {
          '배송': '택배 배송',
          '결제 후': '1-2일 내 출고',
          '배송비': '2,500원 (20,000원 이상 구매 시 무료)',
        },
      ),
      Product(
        id: '6',
        title: '라운더스 오행 레이스',
        imagePath: 'assets/images/ohangrace.JPG',
        originalPrice: 45000,
        price: 45000,
        discountRate: 0,
        category: ProductCategory.clothes,
        description: '라운더스 오행 레이스입니다.',
        shippingInfo: {
          '배송': '택배 배송',
          '결제 후': '1-2일 내 출고',
          '배송비': '2,500원 (20,000원 이상 구매 시 무료)',
        },
      ),
    ];
  }

  // 할인된 가격 계산
  int get discountedPrice {
    if (discountRate == 0) return price;

    return (price * (100 - discountRate) / 100).round();
  }

  // Map에서 Product 객체 생성
  factory Product.fromMap(Map<String, dynamic> map, String id) {
    // 가격 문자열에서 숫자만 추출 (예: "25,000원" -> 25000)
    final priceValue = int.parse(
      map['price']!.replaceAll(',', '').replaceAll('원', ''),
    );

    return Product(
      id: id,
      title: map['title'] ?? '',
      imagePath: map['imagePath'] ?? '',
      price: priceValue,
      originalPrice:
          map['originalPrice'] != null ? int.parse(map['originalPrice']) : null,
      discountRate: map['discountRate'] ?? 0,
      category: ProductCategory.values[map['category'] ?? 0],
      description: map['description'] ?? '',
      shippingInfo: Map.from(map['shippingInfo'] ?? {}),
    );
  }
}

// 장바구니 아이템 클래스
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  // 총 가격 계산
  int get totalPrice => product.discountedPrice * quantity;
}

// 장바구니 상태 관리 클래스
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  // 장바구니 아이템 목록
  List<CartItem> get items => _items;

  // 장바구니 아이템 수
  int get itemCount => _items.length;

  // 장바구니 총 금액
  int get totalAmount {
    return _items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  // 장바구니에 상품 추가
  void addToCart(Product product) {
    // 이미 장바구니에 있는지 확인
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      // 있으면 수량 증가
      _items[existingIndex].quantity++;
    } else {
      // 없으면 새로 추가
      _items.add(CartItem(product: product));
    }

    notifyListeners();
  }

  // 장바구니에서 상품 제거
  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  // 상품 수량 변경
  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      if (_items[index].quantity <= 0) {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  // 장바구니 비우기
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
