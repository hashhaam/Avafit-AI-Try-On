import 'package:flutter/material.dart';
import '../../utils/colors.dart';

class RecentlyViewedScreen extends StatefulWidget {
  const RecentlyViewedScreen({super.key});

  @override
  State<RecentlyViewedScreen> createState() => _RecentlyViewedScreenState();
}

class _RecentlyViewedScreenState extends State<RecentlyViewedScreen> {
  bool isToday = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ---------- HEADER ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 20),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 24),
                    onPressed: () => Navigator.pop(context),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Recently viewed',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // ---------- FILTER PILLS ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _filterPill(
                    label: 'Today',
                    active: isToday,
                    onTap: () => setState(() => isToday = true),
                  ),
                  const SizedBox(width: 12),
                  _filterPill(
                    label: 'Yesterday',
                    active: !isToday,
                    onTap: () => setState(() => isToday = false),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ---------- GRID ----------
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 6,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (_, index) => _productTile(index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterPill({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.purple.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active ? AppColors.purple : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? AppColors.purple : Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            if (active) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check,
                size: 18,
                color: AppColors.purple,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _productTile(int index) {
    final products = [
      {'name': 'Limelight Top', 'price': 'Rs 8,900', 'image': 'assets/images/products/product_1.png'},
      {'name': 'Limelight Skirt', 'price': 'Rs 3,000', 'image': 'assets/images/products/product_2.png'},
      {'name': 'Zara Top', 'price': 'Rs 5,700', 'image': 'assets/images/products/product_3.png'},
      {'name': 'Saya Outwear', 'price': 'Rs 9,000', 'image': 'assets/images/products/product_4.png'},
      {'name': 'Summer Dress', 'price': 'Rs 6,500', 'image': 'assets/images/products/product_5.png'},
      {'name': 'Party Wear', 'price': 'Rs 12,000', 'image': 'assets/images/products/product_6.png'},
    ];
    
    final product = products[index % products.length];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: AssetImage(product['image']!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          product['name']!,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          product['price']!,
          style: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}