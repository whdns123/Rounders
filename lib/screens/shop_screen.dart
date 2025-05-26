import 'package:flutter/material.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  ProductCategory _selectedCategory = ProductCategory.all;
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final int _cartItemCount = 0; // 장바구니 아이템 수

  @override
  void initState() {
    super.initState();
    // 더미 데이터 로드
    _products = Product.getDummyProducts();
    _filteredProducts = _products;
  }

  // 카테고리별 필터링
  void _filterProducts(ProductCategory category) {
    setState(() {
      _selectedCategory = category;

      if (category == ProductCategory.all) {
        _filteredProducts = _products;
      } else {
        _filteredProducts =
            _products.where((product) => product.category == category).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade600,
        title: const Text(
          '라운더스 숍',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  // 장바구니 화면으로 이동 (미구현)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('장바구니 기능은 아직 준비 중입니다.')),
                  );
                },
              ),
              if (_cartItemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 카테고리 필터
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryButton('전체', ProductCategory.all),
                  const SizedBox(width: 8),
                  _buildCategoryButton('게임', ProductCategory.game),
                  const SizedBox(width: 8),
                  _buildCategoryButton('굿즈', ProductCategory.goods),
                  const SizedBox(width: 8),
                  _buildCategoryButton('옷', ProductCategory.clothes),
                ],
              ),
            ),
          ),

          // 상품 그리드
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                return _buildProductCard(_filteredProducts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 카테고리 버튼 위젯
  Widget _buildCategoryButton(String title, ProductCategory category) {
    final bool isSelected = _selectedCategory == category;

    return ElevatedButton(
      onPressed: () => _filterProducts(category),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.indigo.shade100 : Colors.white,
        foregroundColor: isSelected ? Colors.indigo : Colors.black87,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? Colors.indigo.shade300 : Colors.grey.shade300,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Row(
        children: [
          if (isSelected) const Icon(Icons.check, size: 16),
          if (isSelected) const SizedBox(width: 4),
          Text(title),
        ],
      ),
    );
  }

  // 상품 카드 위젯
  Widget _buildProductCard(Product product) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // 상품 상세 페이지로 이동
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상품 이미지
            Stack(
              children: [
                Image.asset(
                  product.imagePath,
                  width: double.infinity,
                  height: 130,
                  fit: BoxFit.cover,
                ),
                // 할인율 배지
                if (product.discountRate > 0)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        '${product.discountRate}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // 상품 정보
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${product.price.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                        style: TextStyle(
                          color: product.discountRate > 0
                              ? Colors.red
                              : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (product.discountRate > 0 &&
                          product.originalPrice != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '${product.originalPrice.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}원',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 12,
                            ),
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
    );
  }
}
