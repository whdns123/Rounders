import 'package:flutter/material.dart';
import '../models/product.dart';

class CartScreen extends StatelessWidget {
  final CartProvider cartProvider;

  const CartScreen({super.key, required this.cartProvider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('장바구니'),
        backgroundColor: Colors.indigo,
        actions: [
          if (cartProvider.itemCount > 0)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: const Text('장바구니 비우기'),
                        content: const Text('장바구니를 비우시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () {
                              cartProvider.clear();
                              Navigator.of(ctx).pop();
                            },
                            child: const Text(
                              '확인',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                );
              },
            ),
        ],
      ),
      body:
          cartProvider.itemCount == 0
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 100,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text('장바구니가 비어 있습니다', style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    Text(
                      '샵에서 원하는 상품을 담아보세요!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                itemCount: cartProvider.items.length,
                itemBuilder:
                    (ctx, i) => CartItemWidget(
                      cartItem: cartProvider.items[i],
                      cartProvider: cartProvider,
                    ),
              ),
      bottomNavigationBar:
          cartProvider.itemCount == 0
              ? BottomAppBar(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                height: 70,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/shop');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('쇼핑 계속하기'),
                ),
              )
              : BottomAppBar(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                height: 120,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('상품 금액', style: TextStyle(fontSize: 16)),
                        Text(
                          '${_formatPrice(cartProvider.totalAmount)}원',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('배송비', style: TextStyle(fontSize: 16)),
                        Text(
                          cartProvider.totalAmount >= 30000 ? '무료' : '3,000원',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '결제 금액',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_formatPrice(cartProvider.totalAmount + (cartProvider.totalAmount >= 30000 ? 0 : 3000))}원',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showOrderDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('주문하기'),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  // 주문 완료 다이얼로그 표시
  void _showOrderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('주문 완료'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text('주문이 성공적으로 완료되었습니다!'),
                const SizedBox(height: 8),
                Text('주문번호: ORDER${DateTime.now().millisecondsSinceEpoch}'),
                const SizedBox(height: 8),
                Text(
                  '결제 금액: ${_formatPrice(cartProvider.totalAmount + (cartProvider.totalAmount >= 30000 ? 0 : 3000))}원',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  cartProvider.clear();
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushReplacementNamed('/home');
                },
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }

  // 가격을 천 단위로 쉼표 포맷팅
  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

// 장바구니 아이템 위젯
class CartItemWidget extends StatelessWidget {
  final CartItem cartItem;
  final CartProvider cartProvider;

  const CartItemWidget({
    super.key,
    required this.cartItem,
    required this.cartProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // 상품 이미지
            Image.asset(
              cartItem.product.image,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 16),
            // 상품 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatPrice(cartItem.product.discountedPrice)}원',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // 수량 조절
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    cartProvider.updateQuantity(
                      cartItem.product.id,
                      cartItem.quantity - 1,
                    );
                  },
                ),
                Text(
                  cartItem.quantity.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    cartProvider.updateQuantity(
                      cartItem.product.id,
                      cartItem.quantity + 1,
                    );
                  },
                ),
              ],
            ),
            // 삭제 버튼
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                cartProvider.removeFromCart(cartItem.product.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 가격을 천 단위로 쉼표 포맷팅
  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
