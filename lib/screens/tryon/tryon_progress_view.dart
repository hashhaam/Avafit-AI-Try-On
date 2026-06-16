import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/colors.dart';

/// Self-contained animated progress view shown while a try-on is generating.
/// Manages its own Timer + AnimationController and cleans them up in dispose(),
/// so it never affects the try-on network logic. When the parent removes it
/// from the tree (processing done), its timer/controller are auto-cancelled.
class TryOnProgressView extends StatefulWidget {
  const TryOnProgressView({super.key});

  @override
  State<TryOnProgressView> createState() => _TryOnProgressViewState();
}

class _TryOnProgressViewState extends State<TryOnProgressView>
    with SingleTickerProviderStateMixin {
  static const List<String> _phases = [
    'Analyzing your photo...',
    'Understanding the garment...',
    'Mapping the perfect fit...',
    'Personalizing your look...',
    'Getting you dressed up...',
    'Adding the final touches...',
    'Almost ready...',
  ];

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  Timer? _ticker;
  int _phaseIndex = 0;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Advances elapsed time every second and the phase message every ~9s.
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
        final nextIndex = _elapsedSeconds ~/ 9;
        _phaseIndex = nextIndex < _phases.length
            ? nextIndex
            : _phases.length - 1;
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String get _elapsedLabel {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Creeps toward 0.95 over ~120s, then holds — never shows "done" until the
    // real result arrives and the parent removes this view.
    final double progress = (_elapsedSeconds / 120).clamp(0.0, 0.95).toDouble();

    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing gradient badge
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: const Icon(Icons.checkroom, color: Colors.white, size: 38),
            ),
          ),
          const SizedBox(height: 26),
          // Phase message with fade transition
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              _phases[_phaseIndex],
              key: ValueKey<int>(_phaseIndex),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Creeping progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.inputBackground,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
            ),
          ),
          const SizedBox(height: 14),
          // Elapsed + expectation hint
          Text(
            '$_elapsedLabel  ·  Usually takes 1-2 minutes',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
