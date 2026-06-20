import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../utils/colors.dart';
import '../../services/tryon_service.dart';
import 'tryon_result_screen.dart';
import 'tryon_progress_view.dart';

class TryOnScreen extends StatefulWidget {
  final File personImage;
  final Map<String, dynamic>? preselectedGarment;

  const TryOnScreen({
    super.key,
    required this.personImage,
    this.preselectedGarment,
  });

  @override
  State<TryOnScreen> createState() => _TryOnScreenState();
}

class _TryOnScreenState extends State<TryOnScreen> {
  static const double _garmentCardMinWidth = 176;
  static const double _garmentCardMaxWidth = 220;
  static const double _garmentImageAspectRatio = 20 / 13;
  static const double _garmentCardSpacing = 16;
  static const double _garmentCardBottomSpacing = 8;
  static const EdgeInsets _garmentInfoPadding = EdgeInsets.fromLTRB(
    12,
    8,
    12,
    8,
  );
  static const TextStyle _garmentNameStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle _garmentBrandStyle = TextStyle(
    fontSize: 13,
    color: Color(0xFF757575),
  );
  static const TextStyle _garmentPriceStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: AppColors.purple,
  );

  List<Map<String, dynamic>> _garments = [];
  String? _selectedGarmentId;
  String _selectedSide = 'front';
  bool _isLoadingGarments = true;
  bool _isProcessing = false;
  final ScrollController _garmentScrollController = ScrollController();

  /// Returns the currently selected garment map, or null if none selected.
  Map<String, dynamic>? get _selectedGarment {
    if (_selectedGarmentId == null) return null;
    for (final g in _garments) {
      if (g['id'] == _selectedGarmentId) return g;
    }
    return null;
  }

  /// True only when the selected garment actually has a back image
  /// (images array with a non-empty second entry). Front-only garments
  /// never show the side picker.
  bool get _selectedGarmentHasBack {
    final g = _selectedGarment;
    if (g == null) return false;
    final images = g['images'];
    return images is List &&
        images.length > 1 &&
        images[1] != null &&
        images[1].toString().isNotEmpty;
  }

  @override
  void dispose() {
    _garmentScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadGarments();
  }

  Future<void> _loadGarments() async {
    setState(() {
      _isLoadingGarments = true;
    });

    try {
      // Use getAllGarmentsFlat to get all garments across brands
      debugPrint('🔄 Loading garments...');

      final garments = await TryOnService.getAllGarmentsFlat();

      debugPrint('✅ Loaded ${garments.length} garments');

      if (!mounted) return;

      // Apply pre-selected garment if provided
      String? preId;
      int preIndex = -1;
      final preGarment = widget.preselectedGarment;
      if (preGarment != null) {
        final pid = preGarment['id']?.toString();
        if (pid != null && pid.isNotEmpty) {
          for (int i = 0; i < garments.length; i++) {
            if (garments[i]['id']?.toString() == pid) {
              preId = pid;
              preIndex = i;
              break;
            }
          }
        }
      }

      setState(() {
        _garments = garments;
        _selectedGarmentId = preId;
        _isLoadingGarments = false;
      });

      if (preIndex >= 0) {
        _scrollToPreselectedGarment(preIndex);
      }
    } catch (e) {
      debugPrint('❌ Garments error: $e');

      if (!mounted) return;
      setState(() {
        _isLoadingGarments = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading garments: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _scrollToPreselectedGarment(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_garmentScrollController.hasClients) return;

      final availableWidth = MediaQuery.sizeOf(context).width;
      final cardExtent =
          _garmentCardWidth(availableWidth) + _garmentCardSpacing;
      final targetOffset = index * cardExtent;
      final maxOffset = _garmentScrollController.position.maxScrollExtent;

      _garmentScrollController.animateTo(
        targetOffset.clamp(0.0, maxOffset).toDouble(),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _performTryOn() async {
    if (_selectedGarmentId == null) {
      return; // Button should be disabled anyway
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final resultUrl = await TryOnService.performTryOn(
        personImage: widget.personImage,
        garmentId: _selectedGarmentId!,
        side: _selectedSide,
      );

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });

      if (resultUrl != null) {
        // Find the selected garment's full data to pass along
        Map<String, dynamic>? selectedGarment;
        for (final g in _garments) {
          if (g['id'] == _selectedGarmentId) {
            selectedGarment = g;
            break;
          }
        }
        // Navigate to result screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TryOnResultScreen(
              resultUrl: resultUrl,
              garment: selectedGarment,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong, please try again'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Virtual Try-On'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Scrollable content keeps the screen responsive on every
              // device size; the Try On button stays pinned at the bottom.
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Person Image Section
                      _buildPersonImageSection(),

                      // Garments List Section
                      _buildGarmentsSection(),

                      // Side Picker (only when the selected garment has a back image)
                      _buildSidePicker(),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Try On Button (pinned at bottom, always visible)
              _buildTryOnButton(),
            ],
          ),

          // Loading Overlay
          if (_isProcessing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildPersonImageSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Photo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: AspectRatio(
                aspectRatio: 1.6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    widget.personImage,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGarmentsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final cardWidth = _garmentCardWidth(availableWidth);
        final placeholderHeight = (cardWidth * 1.2)
            .clamp(210.0, 250.0)
            .toDouble();

        if (_isLoadingGarments) {
          return ConstrainedBox(
            constraints: BoxConstraints(minHeight: placeholderHeight),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (_garments.isEmpty) {
          return ConstrainedBox(
            constraints: BoxConstraints(minHeight: placeholderHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No garments available',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadGarments,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final carouselHeight = _garmentCarouselHeight(context, cardWidth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Select a Garment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(
              height: carouselHeight,
              child: ListView.builder(
                controller: _garmentScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _garments.length,
                itemBuilder: (context, index) {
                  final garment = _garments[index];
                  final isSelected = _selectedGarmentId == garment['id'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedGarmentId = garment['id'];
                        _selectedSide = 'front';
                      });
                    },
                    child: Container(
                      width: cardWidth,
                      margin: const EdgeInsets.only(
                        right: _garmentCardSpacing,
                        bottom: _garmentCardBottomSpacing,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.purple
                              : Colors.grey[300]!,
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Garment Image
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                            child: AspectRatio(
                              aspectRatio: _garmentImageAspectRatio,
                              child: Image.network(
                                garment['image_url']?.toString() ?? '',
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                ),
                                loadingBuilder: (ctx, child, progress) {
                                  if (progress == null) return child;
                                  return Container(
                                    color: Colors.grey[100],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF7C6FCD),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          // Garment Info
                          Expanded(
                            child: Padding(
                              padding: _garmentInfoPadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    garment['name']?.toString() ?? 'Unknown',
                                    style: _garmentNameStyle,
                                    softWrap: true,
                                  ),
                                  Text(
                                    garment['brand_name']?.toString() ?? '',
                                    style: _garmentBrandStyle,
                                    softWrap: true,
                                  ),
                                  Text(
                                    garment['price']?.toString() ?? '',
                                    style: _garmentPriceStyle,
                                    softWrap: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  double _garmentCardWidth(double availableWidth) {
    return (availableWidth * 0.56)
        .clamp(_garmentCardMinWidth, _garmentCardMaxWidth)
        .toDouble();
  }

  double _garmentCarouselHeight(BuildContext context, double cardWidth) {
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    final defaultTextStyle = DefaultTextStyle.of(context).style;
    final textWidth = cardWidth - _garmentInfoPadding.horizontal;
    var tallestInfoHeight = 0.0;

    for (final garment in _garments) {
      final nameHeight = _measureTextHeight(
        garment['name']?.toString() ?? 'Unknown',
        defaultTextStyle.merge(_garmentNameStyle),
        textWidth,
        textScaler,
        textDirection,
      );
      final brandHeight = _measureTextHeight(
        garment['brand_name']?.toString() ?? '',
        defaultTextStyle.merge(_garmentBrandStyle),
        textWidth,
        textScaler,
        textDirection,
      );
      final priceHeight = _measureTextHeight(
        garment['price']?.toString() ?? '',
        defaultTextStyle.merge(_garmentPriceStyle),
        textWidth,
        textScaler,
        textDirection,
      );

      // The current design spaces the three labels apart. Reserve at least
      // 12 logical pixels for those two gaps while allowing all text to wrap.
      final infoHeight = nameHeight + brandHeight + priceHeight + 12;
      tallestInfoHeight = math.max(tallestInfoHeight, infoHeight);
    }

    final imageHeight = cardWidth / _garmentImageAspectRatio;
    final cardHeight =
        imageHeight + _garmentInfoPadding.vertical + tallestInfoHeight;

    return (cardHeight + _garmentCardBottomSpacing).ceilToDouble();
  }

  double _measureTextHeight(
    String text,
    TextStyle style,
    double maxWidth,
    TextScaler textScaler,
    TextDirection textDirection,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      textScaler: textScaler,
    )..layout(maxWidth: maxWidth);

    return painter.height;
  }

  Widget _buildSidePicker() {
    // Hidden unless the selected garment has a usable back image.
    if (!_selectedGarmentHasBack) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Try-On Side',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _sideChip('front', 'Front', Icons.person)),
              const SizedBox(width: 12),
              Expanded(
                child: _sideChip('back', 'Back', Icons.flip_camera_android),
              ),
            ],
          ),
          if (_selectedSide == 'back')
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 15,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Use a back-facing photo for the best back try-on result.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sideChip(String value, String label, IconData icon) {
    final bool selected = _selectedSide == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSide = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.purple : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.purple : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : AppColors.secondaryText,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.primaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTryOnButton() {
    final bool isEnabled = _selectedGarmentId != null && !_isProcessing;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isEnabled ? _performTryOn : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.purple,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Try On',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.7),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 32)
                        .clamp(0.0, double.infinity)
                        .toDouble(),
                  ),
                  child: const Center(child: TryOnProgressView()),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
