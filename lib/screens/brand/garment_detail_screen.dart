import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../camera/camera_screen.dart';

class GarmentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> garment;

  const GarmentDetailScreen({super.key, required this.garment});

  @override
  State<GarmentDetailScreen> createState() => _GarmentDetailScreenState();
}

class _GarmentDetailScreenState extends State<GarmentDetailScreen> {
  static const Color _purple = Color(0xFF7C6FCD);

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isWishlisted = false;
  bool _wishlistBusy = false;

  @override
  void initState() {
    super.initState();
    _checkWishlist();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _images {
    final imgs = widget.garment['images'];
    if (imgs is List && imgs.isNotEmpty) {
      return imgs.map((e) => e.toString()).toList();
    }
    final single = widget.garment['image_url']?.toString() ?? '';
    return single.isEmpty ? [] : [single];
  }

  Future<void> _checkWishlist() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final id = widget.garment['id']?.toString();
      if (uid == null || id == null) return;
      final inList = await FirestoreService.isInWishlist(uid, id);
      if (mounted) setState(() => _isWishlisted = inList);
    } catch (_) {
      // non-fatal
    }
  }

  Future<void> _toggleWishlist() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to use wishlist')),
      );
      return;
    }
    final id = widget.garment['id']?.toString() ?? '';
    if (id.isEmpty || _wishlistBusy) return;

    final wasIn = _isWishlisted;
    setState(() {
      _isWishlisted = !wasIn;
      _wishlistBusy = true;
    });
    try {
      if (wasIn) {
        await FirestoreService.removeFromWishlist(uid, id);
      } else {
        await FirestoreService.addToWishlist(uid, widget.garment);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isWishlisted = wasIn);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update wishlist')),
        );
      }
    } finally {
      if (mounted) setState(() => _wishlistBusy = false);
    }
  }

  void _onTryOn() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScreen(preselectedGarment: widget.garment),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.garment['name']?.toString() ?? 'Garment';
    final brand = widget.garment['brand_name']?.toString() ?? '';
    final price = widget.garment['price']?.toString() ?? '';
    final category = widget.garment['category']?.toString() ?? '';
    final images = _images;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: Text(name, style: const TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(
              _isWishlisted ? Icons.favorite : Icons.favorite_border,
              color: _purple,
            ),
            onPressed: _toggleWishlist,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Expanded(
                    child: images.isEmpty
                        ? const Center(
                            child: Icon(
                              Icons.checkroom,
                              size: 64,
                              color: Colors.grey,
                            ),
                          )
                        : PageView.builder(
                            controller: _pageController,
                            itemCount: images.length,
                            onPageChanged: (i) =>
                                setState(() => _currentPage = i),
                            itemBuilder: (_, index) {
                              return InteractiveViewer(
                                minScale: 0.8,
                                maxScale: 3.0,
                                child: Image.network(
                                  images[index],
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              _purple,
                                            ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stack) =>
                                      const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                      ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (images.length > 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (i) {
                          final active = i == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: active ? _purple : Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (brand.isNotEmpty)
                  Text(
                    brand,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _purple,
                      ),
                    ),
                    if (category.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            color: Colors.white,
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _onTryOn,
                  icon: const Icon(Icons.checkroom),
                  label: const Text(
                    'Try On',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
