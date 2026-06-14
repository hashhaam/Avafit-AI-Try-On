import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/tryon_service.dart';
import '../../services/firestore_service.dart';
import '../camera/camera_screen.dart';
import 'garment_detail_screen.dart';

class BrandCatalogScreen extends StatefulWidget {
  final String brandId;
  final String brandName;
  final String tagline;

  const BrandCatalogScreen({
    super.key,
    required this.brandId,
    required this.brandName,
    this.tagline = '',
  });

  @override
  State<BrandCatalogScreen> createState() => _BrandCatalogScreenState();
}

class _BrandCatalogScreenState extends State<BrandCatalogScreen> {
  static const Color _purple = Color(0xFF7C6FCD);

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _garments = [];
  List<Map<String, dynamic>> _filtered = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  final Set<String> _wishlistIds = {};

  @override
  void initState() {
    super.initState();
    _loadGarments();
  }

  Future<void> _loadGarments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final brandsData = await TryOnService.getGarments();
      final brand = brandsData.firstWhere(
        (b) => b['id'] == widget.brandId,
        orElse: () => <String, dynamic>{},
      );

      final garmentsRaw = (brand['garments'] as List?) ?? [];
      final garments = garmentsRaw
          .map((g) => Map<String, dynamic>.from(g as Map))
          .toList();

      final cats = <String>{'All'};
      for (final g in garments) {
        final c = g['category']?.toString();
        if (c != null && c.isNotEmpty) cats.add(c);
      }

      if (!mounted) return;
      setState(() {
        _garments = garments;
        _categories = cats.toList();
        _selectedCategory = 'All';
        _filtered = List.from(_garments);
        _isLoading = false;
      });

      // Load existing wishlist state (non-fatal: ignore failures)
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final wishlist = await FirestoreService.getWishlist(uid);
          final ids = wishlist
              .map((g) => g['id']?.toString())
              .whereType<String>()
              .toSet();
          if (mounted) {
            setState(() {
              _wishlistIds
                ..clear()
                ..addAll(ids);
            });
          }
        }
      } catch (e) {
        print('⚠️  Could not load wishlist state (non-fatal): $e');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            'Could not load garments. Please check your connection and try again.';
        _isLoading = false;
      });
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == 'All') {
        _filtered = List.from(_garments);
      } else {
        _filtered = _garments
            .where((g) => g['category']?.toString() == category)
            .toList();
      }
    });
  }

  void _onTryOn(Map<String, dynamic> garment) {
    // Carry the selected garment through to the try-on flow.
    final data = Map<String, dynamic>.from(garment);
    data['brand_id'] = widget.brandId;
    data['brand_name'] = widget.brandName;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CameraScreen(preselectedGarment: data)),
    );
  }

  void _openDetail(Map<String, dynamic> garment) {
    final data = Map<String, dynamic>.from(garment);
    data['brand_id'] = widget.brandId;
    data['brand_name'] = widget.brandName;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GarmentDetailScreen(garment: data)),
    );
  }

  Future<void> _onFavorite(Map<String, dynamic> garment) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to use wishlist')),
      );
      return;
    }
    final id = garment['id']?.toString() ?? '';
    if (id.isEmpty) return;

    final wasInWishlist = _wishlistIds.contains(id);
    // Optimistic UI update
    setState(() {
      if (wasInWishlist) {
        _wishlistIds.remove(id);
      } else {
        _wishlistIds.add(id);
      }
    });

    try {
      if (wasInWishlist) {
        await FirestoreService.removeFromWishlist(uid, id);
      } else {
        // Attach brand info so Wishlist screen can display it
        final data = Map<String, dynamic>.from(garment);
        data['brand_id'] = widget.brandId;
        data['brand_name'] = widget.brandName;
        await FirestoreService.addToWishlist(uid, data);
      }
    } catch (e) {
      // Revert on failure
      if (!mounted) return;
      setState(() {
        if (wasInWishlist) {
          _wishlistIds.add(id);
        } else {
          _wishlistIds.remove(id);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update wishlist')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.brandName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (widget.tagline.isNotEmpty)
              Text(
                widget.tagline,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadGarments,
                style: ElevatedButton.styleFrom(backgroundColor: _purple),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_garments.isEmpty) {
      return const Center(
        child: Text(
          'No garments available for this brand yet.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        if (_categories.length > 1) _buildCategoryChips(),
        Expanded(child: _buildGrid()),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final cat = _categories[index];
          final selected = cat == _selectedCategory;
          return ChoiceChip(
            label: Text(cat),
            selected: selected,
            selectedColor: _purple,
            labelStyle: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            backgroundColor: Colors.white,
            onSelected: (_) => _onCategorySelected(cat),
          );
        },
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _filtered.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.62,
      ),
      itemBuilder: (_, index) => _buildGarmentCard(_filtered[index]),
    );
  }

  Widget _buildGarmentCard(Map<String, dynamic> garment) {
    final name = garment['name']?.toString() ?? 'Unnamed';
    final price = garment['price']?.toString() ?? '';
    final imageUrl = garment['image_url']?.toString() ?? '';

    return GestureDetector(
      onTap: () => _openDetail(garment),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: Colors.grey[100],
                      child: imageUrl.isEmpty
                          ? const Icon(
                              Icons.checkroom,
                              size: 48,
                              color: Colors.grey,
                            )
                          : Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stack) =>
                                  const Icon(
                                    Icons.broken_image,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _onFavorite(garment),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _wishlistIds.contains(garment['id']?.toString())
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 18,
                          color: _purple,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    price,
                    style: const TextStyle(
                      color: _purple,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: SizedBox(
                width: double.infinity,
                height: 34,
                child: ElevatedButton(
                  onPressed: () => _onTryOn(garment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Try On',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
